/// VitalSync — Meal DAO (Health Module).
library;

import 'package:drift/drift.dart';
import 'package:vitalsync/core/enums/sync_status.dart';
import 'package:vitalsync/data/local/database.dart';

import '../../tables/health/meals_table.dart';
import '../remote_payload.dart';

part 'meal_dao.g.dart';

/// DAO for meal operations.
@DriftAccessor(tables: [Meals])
class MealDao extends DatabaseAccessor<AppDatabase> with _$MealDaoMixin {
  MealDao(super.db);

  /// Get all meals, newest first.
  Future<List<MealData>> getAll() {
    return (select(
      meals,
    )..orderBy([(tbl) => OrderingTerm.desc(tbl.eatenAt)])).get();
  }

  /// Get meals within a date range, newest first.
  Future<List<MealData>> getByDateRange(DateTime start, DateTime end) {
    return (select(meals)
          ..where(
            (tbl) =>
                tbl.eatenAt.isBiggerOrEqualValue(start) &
                tbl.eatenAt.isSmallerOrEqualValue(end),
          )
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.eatenAt)]))
        .get();
  }

  /// Returns a single meal by ID, or null if not found.
  Future<MealData?> getById(int id) {
    return (select(meals)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Insert a new meal.
  Future<int> insert(MealsCompanion meal) {
    return into(meals).insert(meal);
  }

  /// Update an existing meal.
  Future<bool> updateMeal(MealData meal) {
    return update(meals).replace(meal);
  }

  /// Delete a meal by ID.
  Future<int> deleteMeal(int id) {
    return (delete(meals)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Watch recent meals.
  Stream<List<MealData>> watchRecent({int limit = 20}) {
    return (select(meals)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.eatenAt)])
          ..limit(limit))
        .watch();
  }

  /// Inserts or updates a meal from cloud remote data.
  /// Sets [syncStatus] to [SyncStatus.synced] to prevent re-pushing.
  /// Does NOT trigger sync queue insertion.
  Future<void> upsertFromRemote(int id, Map<String, dynamic> data) async {
    await into(meals).insertOnConflictUpdate(
      MealsCompanion(
        id: Value(id),
        name: Value(data['name'] as String),
        eatenAt: Value(DateTime.parse(data['eatenAt'] as String)),
        notes: Value(data['notes'] as String?),
        tags: Value(encodeJsonColumn(data['tags'], fallback: '[]')),
        syncStatus: const Value(SyncStatus.synced),
        lastModifiedAt: Value(DateTime.parse(data['lastModifiedAt'] as String)),
        createdAt: Value(DateTime.parse(data['createdAt'] as String)),
      ),
    );
  }
}
