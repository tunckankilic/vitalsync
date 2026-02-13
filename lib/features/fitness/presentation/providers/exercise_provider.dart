/// VitalSync — Fitness Module: Exercise Providers.
///
/// Riverpod 2.0 providers for exercise library management
/// with code generation.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/enums/exercise_category.dart';
import '../../../../domain/entities/fitness/exercise.dart';
import '../../../../domain/repositories/fitness/exercise_repository.dart';

part 'exercise_provider.g.dart';

/// Provider for the ExerciseRepository instance
@Riverpod(keepAlive: true)
ExerciseRepository exerciseRepository(Ref ref) {
  return getIt<ExerciseRepository>();
}

/// Provider for the AnalyticsService instance
@Riverpod(keepAlive: true)
AnalyticsService exerciseAnalyticsService(Ref ref) {
  return getIt<AnalyticsService>();
}

/// Stream provider for all exercises
@riverpod
Stream<List<Exercise>> exercises(Ref ref) {
  final repository = ref.watch(exerciseRepositoryProvider);
  return repository.watchAll();
}

/// Family provider for exercises by category
@riverpod
Future<List<Exercise>> exercisesByCategory(
  Ref ref,
  ExerciseCategory category,
) async {
  final repository = ref.watch(exerciseRepositoryProvider);
  return repository.getByCategory(category);
}

/// Family provider for exercise search
@riverpod
Future<List<Exercise>> exerciseSearch(Ref ref, String query) async {
  final repository = ref.watch(exerciseRepositoryProvider);

  // If query is empty, return all exercises
  if (query.trim().isEmpty) {
    return repository.getAll();
  }

  return repository.search(query);
}

/// Notifier for custom exercise CRUD operations
@riverpod
class ExerciseNotifier extends _$ExerciseNotifier {
  @override
  FutureOr<void> build() {
    // No initial state needed
  }

  /// Add a custom exercise
  /// [exercise] - The exercise to add
  Future<int> addCustomExercise(Exercise exercise) async {
    state = const AsyncValue.loading();

    final repository = ref.read(exerciseRepositoryProvider);
    final analytics = ref.read(exerciseAnalyticsServiceProvider);

    final result = await AsyncValue.guard(() async {
      // Ensure the exercise is marked as custom
      final customExercise = exercise.copyWith(isCustom: true);

      final id = await repository.insertCustom(customExercise);

      // Fire analytics event
      await analytics.logExerciseCreated(
        category: customExercise.category.toString(),
      );

      return id;
    });

    state = result.when(
      data: (_) => const AsyncValue.data(null),
      error: AsyncValue.error,
      loading: () => const AsyncValue.loading(),
    );

    if (result.hasError) {
      throw result.error!;
    }

    return result.value as int;
  }

  /// Delete a custom exercise
  /// Only custom exercises can be deleted
  /// [id] - ID of the exercise to delete
  Future<void> deleteExercise(int id) async {
    state = const AsyncValue.loading();

    final repository = ref.read(exerciseRepositoryProvider);

    state = await AsyncValue.guard(() async {
      // Verify exercise is custom before deleting
      final exercise = await repository.getById(id);

      if (exercise == null) {
        throw Exception('Exercise not found');
      }

      if (!exercise.isCustom) {
        throw Exception('Cannot delete default exercises');
      }

      await repository.delete(id);
    });

    if (state.hasError) {
      throw state.error!;
    }
  }
}
