import 'dart:convert';
import 'package:vitalsync/core/enums/sync_enums.dart';
import 'package:vitalsync/data/local/daos/health/meal_dao.dart';
import 'package:vitalsync/data/local/database.dart';
import 'package:vitalsync/data/models/health/meal_model.dart';
import 'package:vitalsync/domain/entities/health/meal.dart';
import 'package:vitalsync/domain/repositories/health/meal_repository.dart';

/// Meals are pushed to the cloud in full: a logged meal is the user's own
/// input and cannot be re-derived from anywhere else.
class MealRepositoryImpl implements MealRepository {
  MealRepositoryImpl(this._dao, this._database);
  final MealDao _dao;
  final AppDatabase _database;

  /// Cloud collection name. Must match the entry in
  /// `SyncService.tablesToSync` and the Lambda's `COLLECTION_PREFIX`.
  static const _collection = 'meals';

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
  Future<int> insert(Meal meal) async {
    final model = MealModel.fromEntity(meal);
    final id = await _dao.insert(model.toCompanion());
    await _database.addToSyncQueue(
      _collection,
      id,
      SyncOperation.insert,
      model.toJson(),
    );
    return id;
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
    await _database.addToSyncQueue(
      _collection,
      model.id,
      SyncOperation.update,
      model.toJson(),
    );
  }

  @override
  Future<void> delete(int id) async {
    await _dao.deleteMeal(id);
    await _database.addToSyncQueue(
      _collection,
      id,
      SyncOperation.delete,
      const {},
    );
  }

  @override
  Stream<List<Meal>> watchRecent({int limit = 20}) {
    return _dao
        .watchRecent(limit: limit)
        .map((list) => list.map(MealModel.fromDrift).toList());
  }
}
