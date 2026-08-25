/// VitalSync — Health Module: Meal Providers.
///
/// Riverpod providers over [MealRepository]. Meals are recorded and listed;
/// nothing here scores, ranks or comments on what was eaten.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../domain/entities/health/meal.dart';
import '../../../../domain/repositories/health/meal_repository.dart';
import '../../domain/services/meal_data_coverage_service.dart';
import '../../domain/services/post_meal_reminder_service.dart';

part 'meal_provider.g.dart';

/// Provider for the MealRepository instance
@Riverpod(keepAlive: true)
MealRepository mealRepository(Ref ref) {
  return getIt<MealRepository>();
}

/// Provider for the MealDataCoverageService instance
@Riverpod(keepAlive: true)
MealDataCoverageService mealDataCoverageService(Ref ref) {
  return getIt<MealDataCoverageService>();
}

/// Provider for the PostMealReminderService instance
@Riverpod(keepAlive: true)
PostMealReminderService postMealReminderService(Ref ref) {
  return getIt<PostMealReminderService>();
}

/// Coverage verdicts for the meals the list is showing, keyed by meal id.
///
/// Data completeness only — see [MealDataCoverageService]. A verdict says
/// whether measurements exist around a meal, never anything about them.
@riverpod
Future<Map<int, MealCoverage>> mealCoverage(Ref ref, {int limit = 50}) async {
  final meals = await ref.watch(mealsProvider(limit: limit).future);
  final service = ref.watch(mealDataCoverageServiceProvider);

  final coverages = await service.evaluateMeals(meals);
  return {for (final coverage in coverages) coverage.mealId: coverage};
}

/// Stream provider for the most recent meals
@riverpod
Stream<List<Meal>> meals(Ref ref, {int limit = 50}) {
  final repository = ref.watch(mealRepositoryProvider);
  return repository.watchRecent(limit: limit);
}

/// Provider for meals in a date range, oldest first.
///
/// Sorted like `glucoseReadingsInDateRangeProvider` so the timeline chart
/// draws both against the same axis.
@riverpod
Future<List<Meal>> mealsInDateRange(
  Ref ref, {
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final repository = ref.watch(mealRepositoryProvider);
  final meals = await repository.getByDateRange(startDate, endDate);
  return meals..sort((a, b) => a.eatenAt.compareTo(b.eatenAt));
}

/// Notifier for meal CRUD operations
@riverpod
class MealNotifier extends _$MealNotifier {
  @override
  FutureOr<void> build() {
    // No initial state needed
  }

  /// Add a new meal
  Future<void> addMeal(Meal meal) async {
    state = const AsyncValue.loading();

    // Read ref-based dependencies up front: this notifier is autoDispose and
    // the add screen pops right after triggering the op, so touching ref
    // after the awaits below would throw on a disposed Ref.
    final repository = ref.read(mealRepositoryProvider);
    final reminderService = ref.read(postMealReminderServiceProvider);

    final result = await AsyncValue.guard(() async {
      final id = await repository.insert(meal);

      // Arm the post-meal measurement reminder (never throws)
      await reminderService.syncReminderAfterChange(id);
    });
    // Guard the state write: this notifier is autoDispose and the add screen
    // pops once the action completes, so an unguarded write throws "Cannot use
    // the Ref ... after it has been disposed".
    if (ref.mounted) state = result;

    if (result.hasError) {
      throw result.error!;
    }
  }

  /// Update an existing meal
  Future<void> updateMeal(Meal meal) async {
    state = const AsyncValue.loading();

    final repository = ref.read(mealRepositoryProvider);
    final reminderService = ref.read(postMealReminderServiceProvider);

    final result = await AsyncValue.guard(() async {
      await repository.update(meal);

      // Move the reminder to match the (possibly changed) meal time
      await reminderService.syncReminderAfterChange(meal.id);
    });
    if (ref.mounted) state = result;

    if (result.hasError) {
      throw result.error!;
    }
  }

  /// Delete a meal
  Future<void> deleteMeal(int id) async {
    state = const AsyncValue.loading();

    final repository = ref.read(mealRepositoryProvider);
    final reminderService = ref.read(postMealReminderServiceProvider);

    final result = await AsyncValue.guard(() async {
      await repository.delete(id);

      // The meal is gone; its pending reminder must go with it
      await reminderService.cancelReminder(id);
    });
    if (ref.mounted) state = result;

    if (result.hasError) {
      throw result.error!;
    }
  }
}
