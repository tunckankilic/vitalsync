/// VitalSync — Health Module: Symptom Providers.
///
/// Riverpod 2.0 providers for symptom tracking and analysis.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../domain/entities/health/symptom.dart';
import '../../../../domain/repositories/health/symptom_repository.dart';
import 'medication_provider.dart';

part 'symptom_provider.g.dart';

/// Provider for the SymptomRepository instance
@Riverpod(keepAlive: true)
SymptomRepository symptomRepository(Ref ref) {
  return getIt<SymptomRepository>();
}

/// Stream provider for all symptoms
@riverpod
Stream<List<Symptom>> symptoms(Ref ref) {
  final repository = ref.watch(symptomRepositoryProvider);
  return repository.watchRecent();
}

/// Stream provider for recent symptoms (last 20)
@riverpod
Stream<List<Symptom>> recentSymptoms(Ref ref, {int limit = 20}) {
  final repository = ref.watch(symptomRepositoryProvider);
  return repository.watchRecent(limit: limit);
}

/// Provider for symptom frequency map (for charts)
/// Returns map of symptom name to occurrence count
@riverpod
Future<Map<String, int>> symptomFrequency(Ref ref, {int days = 30}) async {
  final repository = ref.watch(symptomRepositoryProvider);
  return await repository.getSymptomFrequency(days: days);
}

/// Provider for average severity by symptom name (for insight engine)
/// Returns map of symptom name to average severity (1-5)
@riverpod
Future<Map<String, double>> averageSeverity(Ref ref, {int days = 30}) async {
  final repository = ref.watch(symptomRepositoryProvider);
  return await repository.getAverageSeverityByName(days: days);
}

/// Provider for symptoms in a date range
@riverpod
Future<List<Symptom>> symptomsInDateRange(
  Ref ref, {
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final repository = ref.watch(symptomRepositoryProvider);
  return await repository.getByDateRange(startDate, endDate);
}

/// State provider for selected symptom (for detail screens)
@riverpod
class SelectedSymptom extends _$SelectedSymptom {
  @override
  Symptom? build() => null;

  void select(Symptom? symptom) {
    state = symptom;
  }

  void clear() {
    state = null;
  }
}

/// Notifier for symptom CRUD operations
@riverpod
class SymptomNotifier extends _$SymptomNotifier {
  @override
  FutureOr<void> build() {
    // No initial state needed
  }

  /// Add a new symptom log
  Future<void> addSymptom(Symptom symptom) async {
    state = const AsyncValue.loading();

    final repository = ref.read(symptomRepositoryProvider);
    final analytics = ref.read(analyticsServiceProvider);

    state = await AsyncValue.guard(() async {
      await repository.insert(symptom);

      //Fire analytics event
      await analytics.logSymptomLogged(severity: symptom.severity);
    });

    if (state.hasError) {
      throw state.error!;
    }
  }

  /// Update an existing symptom
  Future<void> updateSymptom(Symptom symptom) async {
    state = const AsyncValue.loading();

    final repository = ref.read(symptomRepositoryProvider);

    state = await AsyncValue.guard(() async {
      await repository.update(symptom);
    });

    if (state.hasError) {
      throw state.error!;
    }
  }

  /// Delete a symptom
  Future<void> deleteSymptom(int id) async {
    state = const AsyncValue.loading();

    final repository = ref.read(symptomRepositoryProvider);

    state = await AsyncValue.guard(() async {
      await repository.delete(id);
    });

    if (state.hasError) {
      throw state.error!;
    }
  }

  /// Get all symptoms (for export/analysis)
  Future<List<Symptom>> getAllSymptoms() async {
    final repository = ref.read(symptomRepositoryProvider);
    return await repository.getAll();
  }
}
