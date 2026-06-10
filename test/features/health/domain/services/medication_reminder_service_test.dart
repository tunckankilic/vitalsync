import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vitalsync/core/constants/app_constants.dart';
import 'package:vitalsync/core/enums/medication_frequency.dart';
import 'package:vitalsync/core/notifications/notification_service.dart';
import 'package:vitalsync/domain/entities/health/medication.dart';
import 'package:vitalsync/domain/repositories/health/medication_repository.dart';
import 'package:vitalsync/features/health/domain/services/medication_reminder_service.dart';

class MockNotificationService extends Mock implements NotificationService {}

class MockMedicationRepository extends Mock implements MedicationRepository {}

void main() {
  late MedicationReminderService service;
  late MockNotificationService mockNotificationService;
  late MockMedicationRepository mockMedicationRepository;
  late bool notificationsEnabled;

  setUp(() {
    mockNotificationService = MockNotificationService();
    mockMedicationRepository = MockMedicationRepository();
    notificationsEnabled = true;
    service = MedicationReminderService(
      notificationService: mockNotificationService,
      medicationRepository: mockMedicationRepository,
      areNotificationsEnabled: () => notificationsEnabled,
    );
    registerFallbackValue(
      Medication(
        id: 1,
        name: 'Test',
        dosage: '10mg',
        frequency: MedicationFrequency.daily,
        times: [],
        startDate: DateTime.now(),
        color: 0,
        isActive: true,
        lastModifiedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  });

  final testMedication = Medication(
    id: 1,
    name: 'Aspirin',
    dosage: '100mg',
    frequency: MedicationFrequency.daily,
    times: ['08:00'],
    startDate: DateTime(2023, 1, 1),
    color: 0xFF000000,
    isActive: true,
    lastModifiedAt: DateTime.now(),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  group('MedicationReminderService', () {
    test('scheduleMedicationReminders schedules daily reminders', () async {
      when(
        () => mockMedicationRepository.getById(1),
      ).thenAnswer((_) async => testMedication);
      when(
        () => mockNotificationService.cancelMedicationReminders(1),
      ).thenAnswer((_) async {});
      when(
        () => mockNotificationService.scheduleDailyMedicationReminders(
          any(),
          withFollowUps: any(named: 'withFollowUps'),
        ),
      ).thenAnswer((_) async {});

      await service.scheduleMedicationReminders(1);

      verify(
        () => mockNotificationService.cancelMedicationReminders(1),
      ).called(1);
      verify(
        () => mockNotificationService.scheduleDailyMedicationReminders(
          testMedication,
          withFollowUps: true,
        ),
      ).called(1);
    });

    test(
      'scheduleMedicationReminders does nothing if medication inactive',
      () async {
        final inactiveMed = testMedication.copyWith(isActive: false);
        when(
          () => mockMedicationRepository.getById(1),
        ).thenAnswer((_) async => inactiveMed);

        await service.scheduleMedicationReminders(1);

        verifyNever(
          () => mockNotificationService.cancelMedicationReminders(any()),
        );
        verifyNever(
          () => mockNotificationService.scheduleDailyMedicationReminders(
            any(),
            withFollowUps: any(named: 'withFollowUps'),
          ),
        );
      },
    );

    test(
      'scheduleMedicationReminders disables follow-ups when notifications '
      'are off in settings',
      () async {
        notificationsEnabled = false;
        when(
          () => mockMedicationRepository.getById(1),
        ).thenAnswer((_) async => testMedication);
        when(
          () => mockNotificationService.cancelMedicationReminders(1),
        ).thenAnswer((_) async {});
        when(
          () => mockNotificationService.scheduleDailyMedicationReminders(
            any(),
            withFollowUps: any(named: 'withFollowUps'),
          ),
        ).thenAnswer((_) async {});

        await service.scheduleMedicationReminders(1);

        verify(
          () => mockNotificationService.scheduleDailyMedicationReminders(
            testMedication,
            withFollowUps: false,
          ),
        ).called(1);
      },
    );

    test('cancelMedicationReminders calls notification service', () async {
      when(
        () => mockNotificationService.cancelMedicationReminders(1),
      ).thenAnswer((_) async {});

      await service.cancelMedicationReminders(1);

      verify(
        () => mockNotificationService.cancelMedicationReminders(1),
      ).called(1);
    });

    test('rescheduleAllReminders cancels all and reschedules active', () async {
      when(
        () => mockNotificationService.cancelAllNotifications(),
      ).thenAnswer((_) async {});
      when(
        () => mockMedicationRepository.getActive(),
      ).thenAnswer((_) async => [testMedication]);
      when(
        () => mockMedicationRepository.getById(1),
      ).thenAnswer((_) async => testMedication);
      when(
        () => mockNotificationService.cancelMedicationReminders(1),
      ).thenAnswer((_) async {});
      when(
        () => mockNotificationService.scheduleDailyMedicationReminders(
          any(),
          withFollowUps: any(named: 'withFollowUps'),
        ),
      ).thenAnswer((_) async {});

      await service.rescheduleAllReminders();

      verify(() => mockNotificationService.cancelAllNotifications()).called(1);
      verify(
        () => mockNotificationService.scheduleDailyMedicationReminders(
          testMedication,
          withFollowUps: true,
        ),
      ).called(1);
    });
  });

  group('handleDoseLogged', () {
    setUp(() {
      when(
        () => mockNotificationService.cancelMedicationFollowUp(any(), any()),
      ).thenAnswer((_) async {});
      when(
        () => mockNotificationService.cancelMedicationFollowUps(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockNotificationService.scheduleMedicationFollowUp(
          med: any(named: 'med'),
          followUpTime: any(named: 'followUpTime'),
          timeIndex: any(named: 'timeIndex'),
        ),
      ).thenAnswer((_) async {});
    });

    test('cancels the follow-up for the logged dose slot', () async {
      when(
        () => mockMedicationRepository.getById(1),
      ).thenAnswer((_) async => testMedication);

      await service.handleDoseLogged(1);

      verify(
        () => mockNotificationService.cancelMedicationFollowUp(1, 0),
      ).called(1);
    });

    test('re-arms the follow-up for the next day after a daily dose log', () async {
      when(
        () => mockMedicationRepository.getById(1),
      ).thenAnswer((_) async => testMedication);

      final before = DateTime.now();
      await service.handleDoseLogged(1);

      final captured =
          verify(
                () => mockNotificationService.scheduleMedicationFollowUp(
                  med: testMedication,
                  followUpTime: captureAny(named: 'followUpTime'),
                  timeIndex: 0,
                ),
              ).captured.single
              as DateTime;

      // Dose slot 08:00 + 30 min grace = 08:30, first instance tomorrow
      expect(captured.hour, 8);
      expect(captured.minute, 30);
      final tomorrow = before.add(const Duration(days: 1));
      expect(captured.day, tomorrow.day);
      expect(captured.month, tomorrow.month);
    });

    test('re-arms weekly follow-up one week ahead', () async {
      final weeklyMed = testMedication.copyWith(
        frequency: MedicationFrequency.weekly,
      );
      when(
        () => mockMedicationRepository.getById(1),
      ).thenAnswer((_) async => weeklyMed);

      final before = DateTime.now();
      await service.handleDoseLogged(1);

      final captured =
          verify(
                () => mockNotificationService.scheduleMedicationFollowUp(
                  med: weeklyMed,
                  followUpTime: captureAny(named: 'followUpTime'),
                  timeIndex: 0,
                ),
              ).captured.single
              as DateTime;

      final nextWeek = before.add(const Duration(days: 7));
      expect(captured.day, nextWeek.day);
      expect(captured.hour, 8);
      expect(captured.minute, 30);
    });

    test('cancels the follow-up nearest to now for multi-dose medications', () async {
      // Build slots around now so the nearest one is deterministic:
      // one slot exactly now, one 6 hours away (wrapped within the day).
      final now = DateTime.now();
      final far = now.add(const Duration(hours: 6));
      String fmt(DateTime t) => '${t.hour}:${t.minute}';
      final multiDoseMed = testMedication.copyWith(
        frequency: MedicationFrequency.twiceDaily,
        times: [fmt(far), fmt(now)],
      );
      when(
        () => mockMedicationRepository.getById(1),
      ).thenAnswer((_) async => multiDoseMed);

      await service.handleDoseLogged(1);

      verify(
        () => mockNotificationService.cancelMedicationFollowUp(1, 1),
      ).called(1);
    });

    test('does not re-arm when notifications are disabled', () async {
      notificationsEnabled = false;
      when(
        () => mockMedicationRepository.getById(1),
      ).thenAnswer((_) async => testMedication);

      await service.handleDoseLogged(1);

      verify(
        () => mockNotificationService.cancelMedicationFollowUp(1, 0),
      ).called(1);
      verifyNever(
        () => mockNotificationService.scheduleMedicationFollowUp(
          med: any(named: 'med'),
          followUpTime: any(named: 'followUpTime'),
          timeIndex: any(named: 'timeIndex'),
        ),
      );
    });

    test('does not re-arm when medication is inactive', () async {
      final inactiveMed = testMedication.copyWith(isActive: false);
      when(
        () => mockMedicationRepository.getById(1),
      ).thenAnswer((_) async => inactiveMed);

      await service.handleDoseLogged(1);

      verify(
        () => mockNotificationService.cancelMedicationFollowUp(1, 0),
      ).called(1);
      verifyNever(
        () => mockNotificationService.scheduleMedicationFollowUp(
          med: any(named: 'med'),
          followUpTime: any(named: 'followUpTime'),
          timeIndex: any(named: 'timeIndex'),
        ),
      );
    });

    test('cancels all follow-ups when the medication no longer exists', () async {
      when(
        () => mockMedicationRepository.getById(1),
      ).thenAnswer((_) async => null);

      await service.handleDoseLogged(1);

      verify(
        () => mockNotificationService.cancelMedicationFollowUps(1),
      ).called(1);
      verifyNever(
        () => mockNotificationService.cancelMedicationFollowUp(any(), any()),
      );
    });

    test('only cancels (no re-arm) for monthly medications', () async {
      final monthlyMed = testMedication.copyWith(
        frequency: MedicationFrequency.monthly,
      );
      when(
        () => mockMedicationRepository.getById(1),
      ).thenAnswer((_) async => monthlyMed);

      await service.handleDoseLogged(1);

      verify(
        () => mockNotificationService.cancelMedicationFollowUp(1, 0),
      ).called(1);
      verifyNever(
        () => mockNotificationService.scheduleMedicationFollowUp(
          med: any(named: 'med'),
          followUpTime: any(named: 'followUpTime'),
          timeIndex: any(named: 'timeIndex'),
        ),
      );
    });

    test('never throws when the notification service fails', () async {
      when(
        () => mockMedicationRepository.getById(1),
      ).thenAnswer((_) async => testMedication);
      when(
        () => mockNotificationService.cancelMedicationFollowUp(any(), any()),
      ).thenThrow(Exception('plugin failure'));

      await expectLater(service.handleDoseLogged(1), completes);
    });
  });

  group('grace period constant', () {
    test('defaults to 30 minutes', () {
      expect(AppConstants.medicationFollowUpGraceMinutes, 30);
    });
  });
}
