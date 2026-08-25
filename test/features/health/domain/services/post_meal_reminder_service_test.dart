import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vitalsync/core/constants/app_constants.dart';
import 'package:vitalsync/core/notifications/notification_service.dart';
import 'package:vitalsync/domain/entities/health/meal.dart';
import 'package:vitalsync/domain/repositories/health/meal_repository.dart';
import 'package:vitalsync/features/health/domain/services/post_meal_reminder_service.dart';

class MockNotificationService extends Mock implements NotificationService {}

class MockMealRepository extends Mock implements MealRepository {}

void main() {
  late PostMealReminderService service;
  late MockNotificationService mockNotificationService;
  late MockMealRepository mockMealRepository;
  late bool notificationsEnabled;
  late bool reminderEnabled;

  /// Fixed clock, so "already in the past" is decided by the test.
  final now = DateTime(2026, 8, 25, 12, 0);

  const mealId = 7;

  final meal = Meal(
    id: mealId,
    name: 'Lunch',
    eatenAt: DateTime(2026, 8, 25, 11, 30),
    tags: const [],
    lastModifiedAt: now,
    createdAt: now,
  );

  setUp(() {
    mockNotificationService = MockNotificationService();
    mockMealRepository = MockMealRepository();
    notificationsEnabled = true;
    reminderEnabled = true;

    service = PostMealReminderService(
      notificationService: mockNotificationService,
      mealRepository: mockMealRepository,
      areNotificationsEnabled: () => notificationsEnabled,
      isReminderEnabled: () => reminderEnabled,
      now: () => now,
    );

    when(
      () => mockNotificationService.cancelPostMealGlucoseReminder(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.schedulePostMealGlucoseReminder(
        mealId: any(named: 'mealId'),
        remindAt: any(named: 'remindAt'),
      ),
    ).thenAnswer((_) async {});
  });

  group('scheduling', () {
    test('a logged meal schedules a reminder 2 hours after it was eaten',
        () async {
      when(
        () => mockMealRepository.getById(mealId),
      ).thenAnswer((_) async => meal);

      await service.syncReminderAfterChange(mealId);

      final captured = verify(
        () => mockNotificationService.schedulePostMealGlucoseReminder(
          mealId: mealId,
          remindAt: captureAny(named: 'remindAt'),
        ),
      ).captured.single as DateTime;

      expect(
        captured,
        meal.eatenAt.add(
          const Duration(hours: AppConstants.postMealReminderDelayHours),
        ),
      );
    });

    test('the pending reminder is cancelled before a new one is scheduled',
        () async {
      when(
        () => mockMealRepository.getById(mealId),
      ).thenAnswer((_) async => meal);

      await service.syncReminderAfterChange(mealId);

      verifyInOrder([
        () => mockNotificationService.cancelPostMealGlucoseReminder(mealId),
        () => mockNotificationService.schedulePostMealGlucoseReminder(
              mealId: mealId,
              remindAt: any(named: 'remindAt'),
            ),
      ]);
    });

    test('an edited meal time moves the reminder with it', () async {
      final movedMeal = meal.copyWith(eatenAt: DateTime(2026, 8, 25, 11, 45));
      when(
        () => mockMealRepository.getById(mealId),
      ).thenAnswer((_) async => movedMeal);

      await service.syncReminderAfterChange(mealId);

      final captured = verify(
        () => mockNotificationService.schedulePostMealGlucoseReminder(
          mealId: mealId,
          remindAt: captureAny(named: 'remindAt'),
        ),
      ).captured.single as DateTime;

      expect(captured, DateTime(2026, 8, 25, 13, 45));
    });

    test('a meal logged after the fact schedules nothing', () async {
      // Eaten more than 2 hours ago: the reminder time has already passed and
      // must not fire the moment the meal is saved.
      final oldMeal = meal.copyWith(eatenAt: DateTime(2026, 8, 25, 8, 0));
      when(
        () => mockMealRepository.getById(mealId),
      ).thenAnswer((_) async => oldMeal);

      await service.syncReminderAfterChange(mealId);

      verify(
        () => mockNotificationService.cancelPostMealGlucoseReminder(mealId),
      ).called(1);
      verifyNever(
        () => mockNotificationService.schedulePostMealGlucoseReminder(
          mealId: any(named: 'mealId'),
          remindAt: any(named: 'remindAt'),
        ),
      );
    });
  });

  group('cancellation', () {
    test('a deleted meal cancels its reminder', () async {
      await service.cancelReminder(mealId);

      verify(
        () => mockNotificationService.cancelPostMealGlucoseReminder(mealId),
      ).called(1);
    });

    test('syncing a meal that no longer exists only cancels', () async {
      when(() => mockMealRepository.getById(mealId)).thenAnswer((_) async => null);

      await service.syncReminderAfterChange(mealId);

      verify(
        () => mockNotificationService.cancelPostMealGlucoseReminder(mealId),
      ).called(1);
      verifyNever(
        () => mockNotificationService.schedulePostMealGlucoseReminder(
          mealId: any(named: 'mealId'),
          remindAt: any(named: 'remindAt'),
        ),
      );
    });
  });

  group('settings gate', () {
    test('nothing is scheduled while the reminder setting is off', () async {
      reminderEnabled = false;

      await service.syncReminderAfterChange(mealId);

      verifyNever(
        () => mockNotificationService.schedulePostMealGlucoseReminder(
          mealId: any(named: 'mealId'),
          remindAt: any(named: 'remindAt'),
        ),
      );
      // The meal is never even read when the switch is off
      verifyNever(() => mockMealRepository.getById(any()));
    });

    test('nothing is scheduled while notifications are off as a whole',
        () async {
      notificationsEnabled = false;

      await service.syncReminderAfterChange(mealId);

      verifyNever(
        () => mockNotificationService.schedulePostMealGlucoseReminder(
          mealId: any(named: 'mealId'),
          remindAt: any(named: 'remindAt'),
        ),
      );
      verifyNever(() => mockMealRepository.getById(any()));
    });

    test('a pending reminder is still cancelled when a switch is off',
        () async {
      reminderEnabled = false;

      await service.syncReminderAfterChange(mealId);

      verify(
        () => mockNotificationService.cancelPostMealGlucoseReminder(mealId),
      ).called(1);
    });
  });

  group('failure handling', () {
    test('a repository failure does not escape the service', () async {
      when(
        () => mockMealRepository.getById(mealId),
      ).thenThrow(Exception('db down'));

      await expectLater(service.syncReminderAfterChange(mealId), completes);
    });

    test('a cancellation failure does not escape the service', () async {
      when(
        () => mockNotificationService.cancelPostMealGlucoseReminder(mealId),
      ).thenThrow(Exception('plugin down'));

      await expectLater(service.cancelReminder(mealId), completes);
    });
  });
}
