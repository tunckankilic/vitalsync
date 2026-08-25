import 'package:vitalsync/domain/entities/health/meal.dart';

abstract class MealRepository {
  Future<List<Meal>> getAll();
  Future<List<Meal>> getByDateRange(DateTime start, DateTime end);
  Future<Meal?> getById(int id);
  Future<int> insert(Meal meal);
  Future<void> update(Meal meal);
  Future<void> delete(int id);
  Stream<List<Meal>> watchRecent({int limit = 20});
}
