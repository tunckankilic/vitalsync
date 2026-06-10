import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vitalsync/core/analytics/analytics_service.dart';
import 'package:vitalsync/core/enums/medication_log_status.dart';
import 'package:vitalsync/domain/repositories/health/medication_log_repository.dart';
import 'package:vitalsync/features/health/domain/services/medication_reminder_service.dart';
import 'package:vitalsync/features/health/presentation/providers/medication_log_provider.dart';
import 'package:vitalsync/features/health/presentation/providers/medication_provider.dart';

class MockMedicationLogRepository extends Mock
    implements MedicationLogRepository {}

class MockMedicationReminderService extends Mock
    implements MedicationReminderService {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  late MockMedicationLogRepository mockLogRepo;
  late MockMedicationReminderService mockReminderService;
  late MockAnalyticsService mockAnalytics;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(MedicationLogStatus.taken);
  });

  setUp(() {
    mockLogRepo = MockMedicationLogRepository();
    mockReminderService = MockMedicationReminderService();
    mockAnalytics = MockAnalyticsService();

    container = ProviderContainer(
      overrides: [
        medicationLogRepositoryProvider.overrideWithValue(mockLogRepo),
        medicationReminderServiceProvider.overrideWithValue(
          mockReminderService,
        ),
        analyticsServiceProvider.overrideWithValue(mockAnalytics),
      ],
    );

    when(
      () => mockLogRepo.logMedication(any(), any()),
    ).thenAnswer((_) async {});
    when(() => mockAnalytics.logMedicationTaken()).thenAnswer((_) async {});
    when(() => mockAnalytics.logMedicationSkipped()).thenAnswer((_) async {});
    when(
      () => mockReminderService.handleDoseLogged(any()),
    ).thenAnswer((_) async {});
  });

  tearDown(() => container.dispose());

  group('LogMedicationNotifier follow-up cancellation', () {
    test('logAsTaken cancels the pending follow-up for the dose', () async {
      await container
          .read(logMedicationProvider.notifier)
          .logAsTaken(1, DateTime.now());

      verify(
        () => mockLogRepo.logMedication(1, MedicationLogStatus.taken),
      ).called(1);
      verify(() => mockReminderService.handleDoseLogged(1)).called(1);
    });

    test('logAsSkipped also cancels the pending follow-up', () async {
      await container
          .read(logMedicationProvider.notifier)
          .logAsSkipped(1, DateTime.now());

      verify(
        () => mockLogRepo.logMedication(1, MedicationLogStatus.skipped),
      ).called(1);
      verify(() => mockReminderService.handleDoseLogged(1)).called(1);
    });

    test('follow-up is not touched when persisting the log fails', () async {
      when(
        () => mockLogRepo.logMedication(any(), any()),
      ).thenThrow(Exception('db failure'));

      await expectLater(
        container
            .read(logMedicationProvider.notifier)
            .logAsTaken(1, DateTime.now()),
        throwsException,
      );

      verifyNever(() => mockReminderService.handleDoseLogged(any()));
    });
  });
}
