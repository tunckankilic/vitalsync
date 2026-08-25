import 'dart:convert';
import 'package:vitalsync/data/local/daos/health/meal_dao.dart';
import 'package:vitalsync/data/local/database.dart';
import 'package:vitalsync/data/models/health/meal_model.dart';
import 'package:vitalsync/domain/entities/health/meal.dart';
import 'package:vitalsync/domain/repositories/health/meal_repository.dart';

class MealRepositoryImpl implements MealRepository {
  MealRepositoryImpl(this._dao);
  final MealDao _dao;

  @override
  Future<List<Meal>> getAll() async {
    final results = await _dao.getAll();
    return results.map(MealModel.fromDrift).toList();
  }

  @override
  Future<List<Meal>> getByDateRange(DateTime start, DateTime end) async {
    final results = await _dao.getByDateRange(start, end);
    return results.map(MealModel.fromDrift).toList();
  }

  @override
  Future<Meal?> getById(int id) async {
    final result = await _dao.getById(id);
    return result == null ? null : MealModel.fromDrift(result);
  }

  @override
  Future<int> insert(Meal meal) {
    return _dao.insert(MealModel.fromEntity(meal).toCompanion());
  }

  @override
  Future<void> update(Meal meal) async {
    final model = MealModel.fromEntity(meal);
    final data = MealData(
      id: model.id,
      name: model.name,
      eatenAt: model.eatenAt,
      notes: model.notes,
      tags: jsonEncode(
        model.tags,
      ), // Converted to JSON string as Drift expects String
      syncStatus: model.syncStatus,
      lastModifiedAt: model.lastModifiedAt,
      createdAt: model.createdAt,
    );
    await _dao.updateMeal(data);
  }

  @override
  Future<void> delete(int id) {
    return _dao.deleteMeal(id);
  }

  @override
  Stream<List<Meal>> watchRecent({int limit = 20}) {
    return _dao
        .watchRecent(limit: limit)
        .map((list) => list.map(MealModel.fromDrift).toList());
  }
}
