import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vitalsync/core/analytics/analytics_service.dart';
import 'package:vitalsync/core/enums/medication_frequency.dart';
import 'package:vitalsync/domain/entities/health/medication.dart';
import 'package:vitalsync/domain/repositories/health/medication_repository.dart';
import 'package:vitalsync/features/health/domain/services/medication_reminder_service.dart';
import 'package:vitalsync/features/health/presentation/providers/medication_provider.dart';

class MockMedicationRepository extends Mock implements MedicationRepository {}

class MockMedicationReminderService extends Mock
    implements MedicationReminderService {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  late MockMedicationRepository mockRepo;
  late MockMedicationReminderService mockReminderService;
  late MockAnalyticsService mockAnalytics;
  late ProviderContainer container;

  final testMedication = Medication(
    id: 7,
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

  setUpAll(() {
    registerFallbackValue(testMedication);
  });

  setUp(() {
    mockRepo = MockMedicationRepository();
    mockReminderService = MockMedicationReminderService();
    mockAnalytics = MockAnalyticsService();

    container = ProviderContainer(
      overrides: [
        medicationRepositoryProvider.overrideWithValue(mockRepo),
        medicationReminderServiceProvider.overrideWithValue(
          mockReminderService,
        ),
        analyticsServiceProvider.overrideWithValue(mockAnalytics),
      ],
    );

    when(
      () => mockAnalytics.logMedicationAdded(
        frequency: any(named: 'frequency'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockReminderService.syncRemindersAfterChange(any()),
    ).thenAnswer((_) async {});
  });

  tearDown(() => container.dispose());

  group('MedicationNotifier reminder wiring', () {
    test('addMedication schedules reminders for the new id', () async {
      when(() => mockRepo.insert(any())).thenAnswer((_) async => 7);

      final id = await container
          .read(medicationProvider.notifier)
          .addMedication(testMedication);

      expect(id, 7);
      verify(() => mockRepo.insert(testMedication)).called(1);
      verify(() => mockReminderService.syncRemindersAfterChange(7)).called(1);
    });

    test('updateMedication reschedules reminders', () async {
      when(() => mockRepo.update(any())).thenAnswer((_) async {});

      await container
          .read(medicationProvider.notifier)
          .updateMedication(testMedication);

      verify(() => mockRepo.update(testMedication)).called(1);
      verify(() => mockReminderService.syncRemindersAfterChange(7)).called(1);
    });

    test('deleteMedication cancels reminders', () async {
      when(() => mockRepo.delete(any())).thenAnswer((_) async {});

      await container.read(medicationProvider.notifier).deleteMedication(7);

      verify(() => mockRepo.delete(7)).called(1);
      verify(() => mockReminderService.syncRemindersAfterChange(7)).called(1);
    });

    test('toggleActive syncs reminders with the new state', () async {
      when(() => mockRepo.toggleActive(any())).thenAnswer((_) async {});

      await container.read(medicationProvider.notifier).toggleActive(7);

      verify(() => mockRepo.toggleActive(7)).called(1);
      verify(() => mockReminderService.syncRemindersAfterChange(7)).called(1);
    });

    test('reminders are not touched when the repository fails', () async {
      when(() => mockRepo.insert(any())).thenThrow(Exception('db failure'));

      await expectLater(
        container
            .read(medicationProvider.notifier)
            .addMedication(testMedication),
        throwsException,
      );

      verifyNever(() => mockReminderService.syncRemindersAfterChange(any()));
    });
  });
}
