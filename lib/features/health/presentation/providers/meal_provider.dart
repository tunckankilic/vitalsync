/// VitalSync — Health Module: Meal Providers.
///
/// Riverpod providers over [MealRepository]. Meals are recorded and listed;
/// nothing here scores, ranks or comments on what was eaten.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../domain/entities/health/meal.dart';
import '../../../../domain/repositories/health/meal_repository.dart';

part 'meal_provider.g.dart';

/// Provider for the MealRepository instance
@Riverpod(keepAlive: true)
MealRepository mealRepository(Ref ref) {
  return getIt<MealRepository>();
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

    final repository = ref.read(mealRepositoryProvider);

    final result = await AsyncValue.guard(() async {
      await repository.insert(meal);
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

    final result = await AsyncValue.guard(() async {
      await repository.update(meal);
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

    final result = await AsyncValue.guard(() async {
      await repository.delete(id);
    });
    if (ref.mounted) state = result;

    if (result.hasError) {
      throw result.error!;
    }
  }
}
