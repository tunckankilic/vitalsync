/// VitalSync — Health Module: Medication Log Providers.
///
/// Riverpod 2.0 providers for medication log tracking and compliance.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/enums/medication_log_status.dart';
import '../../../../domain/entities/health/medication_log.dart';
import '../../../../domain/repositories/health/medication_log_repository.dart';
import 'medication_provider.dart';

part 'medication_log_provider.g.dart';

/// Provider for the MedicationLogRepository instance
@Riverpod(keepAlive: true)
MedicationLogRepository medicationLogRepository(Ref ref) {
  return getIt<MedicationLogRepository>();
}

/// Stream provider for today's medication logs
@riverpod
Stream<List<MedicationLog>> todayLogs(Ref ref) {
  final repository = ref.watch(medicationLogRepositoryProvider);
  return repository.watchTodayLogs();
}

/// Family provider for compliance rate of a specific medication
@riverpod
Future<double> complianceRate(Ref ref, int medicationId, {int days = 7}) async {
  final repository = ref.watch(medicationLogRepositoryProvider);
  return await repository.getComplianceRate(medicationId, days: days);
}

/// Provider for weekly compliance rate (last 7 days)
@riverpod
Future<double> weeklyCompliance(Ref ref) async {
  final repository = ref.watch(medicationLogRepositoryProvider);
  return await repository.getOverallComplianceRate(days: 7);
}

/// Provider for overall compliance rate (last 30 days)
@riverpod
Future<double> overallCompliance(Ref ref) async {
  final repository = ref.watch(medicationLogRepositoryProvider);
  return await repository.getOverallComplianceRate(days: 30);
}

/// Provider for weekday compliance map (for insight engine)
/// Returns a map of weekday (1-7, Monday-Sunday) to compliance percentage
@riverpod
Future<Map<int, double>> weekdayComplianceMap(Ref ref, {int days = 30}) async {
  final repository = ref.watch(medicationLogRepositoryProvider);
  return await repository.getWeekdayComplianceMap(days: days);
}

/// Provider for logs within a date range
@riverpod
Future<List<MedicationLog>> logsInDateRange(
  Ref ref, {
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final repository = ref.watch(medicationLogRepositoryProvider);
  return await repository.getByDateRange(startDate, endDate);
}

/// Notifier for logging medication actions
@riverpod
class LogMedicationNotifier extends _$LogMedicationNotifier {
  @override
  FutureOr<void> build() {
    // No initial state needed
  }

  /// Log a medication as taken
  Future<void> logAsTaken(
    int medicationId,
    DateTime scheduledTime, {
    String? notes,
  }) async {
    state = const AsyncValue.loading();

    final repository = ref.read(medicationLogRepositoryProvider);
    final analytics = ref.read(analyticsServiceProvider);

    state = await AsyncValue.guard(() async {
      await repository.logMedication(medicationId, MedicationLogStatus.taken);

      // Fire analytics event
      await analytics.logMedicationTaken();
    });

    if (state.hasError) {
      throw state.error!;
    }
  }

  /// Log a medication as skipped
  Future<void> logAsSkipped(
    int medicationId,
    DateTime scheduledTime, {
    String? notes,
  }) async {
    state = const AsyncValue.loading();

    final repository = ref.read(medicationLogRepositoryProvider);
    final analytics = ref.read(analyticsServiceProvider);

    state = await AsyncValue.guard(() async {
      await repository.logMedication(medicationId, MedicationLogStatus.skipped);

      // Fire analytics event
      await analytics.logMedicationSkipped();
    });

    if (state.hasError) {
      throw state.error!;
    }
  }

  /// Update an existing medication log
  Future<void> updateLog(MedicationLog log) async {
    state = const AsyncValue.loading();

    final repository = ref.read(medicationLogRepositoryProvider);

    state = await AsyncValue.guard(() async {
      // Note: Update method needs to be added to repository interface
      // For now, we'll log a new entry
      await repository.logMedication(log.medicationId, log.status);
    });

    if (state.hasError) {
      throw state.error!;
    }
  }

  /// Get logs for a specific medication
  Future<List<MedicationLog>> getLogsForMedication(int medicationId) async {
    final repository = ref.read(medicationLogRepositoryProvider);
    return await repository.getByMedicationId(medicationId);
  }
}
