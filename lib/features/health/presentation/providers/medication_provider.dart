/// VitalSync — Health Module: Medication Providers.
///
/// Riverpod 2.0 providers for medication management with code generation.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/enums/medication_frequency.dart';
import '../../../../domain/entities/health/medication.dart';
import '../../../../domain/repositories/health/medication_repository.dart';
import '../../domain/services/medication_reminder_service.dart';

part 'medication_provider.g.dart';

/// Provider for the MedicationRepository instance
@Riverpod(keepAlive: true)
MedicationRepository medicationRepository(Ref ref) {
  return getIt<MedicationRepository>();
}

/// Provider for the AnalyticsService instance
@Riverpod(keepAlive: true)
AnalyticsService analyticsService(Ref ref) {
  return getIt<AnalyticsService>();
}

/// Provider for the MedicationReminderService instance
@Riverpod(keepAlive: true)
MedicationReminderService medicationReminderService(Ref ref) {
  return getIt<MedicationReminderService>();
}

/// Stream provider for all medications
@riverpod
Stream<List<Medication>> medications(Ref ref) {
  final repository = ref.watch(medicationRepositoryProvider);
  return repository.watchAll();
}

/// Stream provider for active medications only
@riverpod
Stream<List<Medication>> activeMedications(Ref ref) {
  final repository = ref.watch(medicationRepositoryProvider);
  return repository.watchActive();
}

/// Provider for today's medications (computed from active medications)
@riverpod
Future<List<Medication>> todayMedications(Ref ref) async {
  final repository = ref.watch(medicationRepositoryProvider);
  final activeMeds = await repository.getActive();

  // Filter medications that should be taken today based on frequency
  final now = DateTime.now();
  return activeMeds.where((med) {
    if (med.endDate != null && now.isAfter(med.endDate!)) {
      return false;
    }

    // Check if medication should be taken today based on frequency
    switch (med.frequency) {
      case MedicationFrequency.daily:
      case MedicationFrequency.twiceDaily:
      case MedicationFrequency.threeTimesDaily:
        return true;
      case MedicationFrequency.weekly:
        // Check if today matches the scheduled day
        final daysSinceStart = now.difference(med.startDate).inDays;
        return daysSinceStart % 7 == 0;
      case MedicationFrequency.monthly:
        // Check if today is the scheduled day of month
        return now.day == med.startDate.day;
      case MedicationFrequency.asNeeded:
        return true;
    }
  }).toList();
}

/// State provider for selected medication (for detail screens)
@riverpod
class SelectedMedication extends _$SelectedMedication {
  @override
  Medication? build() => null;

  void select(Medication? medication) {
    state = medication;
  }

  void clear() {
    state = null;
  }
}

/// Notifier for medication CRUD operations
@riverpod
class MedicationNotifier extends _$MedicationNotifier {
  @override
  FutureOr<void> build() {
    // No initial state needed
  }

  /// Add a new medication
  Future<int> addMedication(Medication medication) async {
    state = const AsyncValue.loading();

    // Read ref-based dependencies up front. This notifier is autoDispose and
    // the add screen stops listening (pops) right after triggering the op, so
    // touching ref after the awaits below threw "Cannot use the Ref ... after
    // it has been disposed". The captured services stay valid regardless.
    final repository = ref.read(medicationRepositoryProvider);
    final analytics = ref.read(analyticsServiceProvider);
    final reminderService = ref.read(medicationReminderServiceProvider);

    final result = await AsyncValue.guard(() async {
      final id = await repository.insert(medication);

      // Fire analytics event
      await analytics.logMedicationAdded(
        frequency: medication.frequency.toString(),
      );

      // Schedule reminders for the new medication (never throws)
      await reminderService.syncRemindersAfterChange(id);

      return id;
    });

    if (ref.mounted) {
      state = result.when(
        data: (_) => const AsyncValue.data(null),
        error: AsyncValue.error,
        loading: () => const AsyncValue.loading(),
      );
    }

    if (result.hasError) {
      throw result.error!;
    }

    return result.value as int;
  }

  /// Update an existing medication
  Future<void> updateMedication(Medication medication) async {
    state = const AsyncValue.loading();

    final repository = ref.read(medicationRepositoryProvider);
    final reminderService = ref.read(medicationReminderServiceProvider);

    final result = await AsyncValue.guard(() async {
      await repository.update(medication);

      // Reschedule reminders with the updated times (never throws)
      await reminderService.syncRemindersAfterChange(medication.id);
    });
    if (ref.mounted) state = result;

    if (result.hasError) {
      throw result.error!;
    }
  }

  /// Delete a medication
  Future<void> deleteMedication(int id) async {
    state = const AsyncValue.loading();

    final repository = ref.read(medicationRepositoryProvider);
    final reminderService = ref.read(medicationReminderServiceProvider);

    final result = await AsyncValue.guard(() async {
      await repository.delete(id);

      // Cancel reminders for the removed medication (never throws)
      await reminderService.syncRemindersAfterChange(id);
    });
    if (ref.mounted) state = result;

    if (result.hasError) {
      throw result.error!;
    }
  }

  /// Toggle medication active status
  Future<void> toggleActive(int id) async {
    state = const AsyncValue.loading();

    final repository = ref.read(medicationRepositoryProvider);
    final reminderService = ref.read(medicationReminderServiceProvider);

    final result = await AsyncValue.guard(() async {
      await repository.toggleActive(id);

      // Schedule or cancel reminders to match the new state (never throws)
      await reminderService.syncRemindersAfterChange(id);
    });
    if (ref.mounted) state = result;

    if (result.hasError) {
      throw result.error!;
    }
  }
}
