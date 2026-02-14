import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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

  setUp(() {
    mockNotificationService = MockNotificationService();
    mockMedicationRepository = MockMedicationRepository();
    service = MedicationReminderService(
      notificationService: mockNotificationService,
      medicationRepository: mockMedicationRepository,
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
        () => mockNotificationService.scheduleDailyMedicationReminders(any()),
      ).thenAnswer((_) async {});

      await service.scheduleMedicationReminders(1);

      verify(
        () => mockNotificationService.cancelMedicationReminders(1),
      ).called(1);
      verify(
        () => mockNotificationService.scheduleDailyMedicationReminders(
          testMedication,
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
          () => mockNotificationService.scheduleDailyMedicationReminders(any()),
        );
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
        () => mockNotificationService.scheduleDailyMedicationReminders(any()),
      ).thenAnswer((_) async {});

      await service.rescheduleAllReminders();

      verify(() => mockNotificationService.cancelAllNotifications()).called(1);
      verify(
        () => mockNotificationService.scheduleDailyMedicationReminders(
          testMedication,
        ),
      ).called(1);
    });
  });
}
