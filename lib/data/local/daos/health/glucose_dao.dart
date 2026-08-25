/// VitalSync — Glucose Reading DAO (Health Module).
library;

import 'package:drift/drift.dart';
import 'package:vitalsync/core/enums/glucose_source.dart';
import 'package:vitalsync/core/enums/meal_context.dart';
import 'package:vitalsync/core/enums/sync_status.dart';
import 'package:vitalsync/data/local/database.dart';

import '../../tables/health/glucose_readings_table.dart';

part 'glucose_dao.g.dart';

/// DAO for blood glucose reading operations.
@DriftAccessor(tables: [GlucoseReadings])
class GlucoseDao extends DatabaseAccessor<AppDatabase> with _$GlucoseDaoMixin {
  GlucoseDao(super.db);

  /// Get all glucose readings, newest first.
  Future<List<GlucoseReadingData>> getAll() {
    return (select(
      glucoseReadings,
    )..orderBy([(tbl) => OrderingTerm.desc(tbl.measuredAt)])).get();
  }

  /// Get glucose readings within a date range, newest first.
  Future<List<GlucoseReadingData>> getByDateRange(
    DateTime start,
    DateTime end,
  ) {
    return (select(glucoseReadings)
          ..where(
            (tbl) =>
                tbl.measuredAt.isBiggerOrEqualValue(start) &
                tbl.measuredAt.isSmallerOrEqualValue(end),
          )
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.measuredAt)]))
        .get();
  }

  /// Returns a single glucose reading by ID, or null if not found.
  Future<GlucoseReadingData?> getById(int id) {
    return (select(
      glucoseReadings,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Insert a new glucose reading.
  Future<int> insert(GlucoseReadingsCompanion reading) {
    return into(glucoseReadings).insert(reading);
  }

  /// Update an existing glucose reading.
  Future<bool> updateReading(GlucoseReadingData reading) {
    return update(glucoseReadings).replace(reading);
  }

  /// Delete a glucose reading by ID.
  Future<int> deleteReading(int id) {
    return (delete(glucoseReadings)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Watch recent glucose readings.
  Stream<List<GlucoseReadingData>> watchRecent({int limit = 20}) {
    return (select(glucoseReadings)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.measuredAt)])
          ..limit(limit))
        .watch();
  }

  /// Whether a reading with the given external store ID already exists.
  /// Used to deduplicate repeated imports from the platform health store.
  Future<bool> existsByExternalId(String externalId) async {
    final row = await (select(
      glucoseReadings,
    )..where((tbl) => tbl.externalId.equals(externalId))).getSingleOrNull();
    return row != null;
  }

  /// Inserts or updates a glucose reading from cloud remote data.
  /// Sets [syncStatus] to [SyncStatus.synced] to prevent re-pushing.
  /// Does NOT trigger sync queue insertion.
  Future<void> upsertFromRemote(int id, Map<String, dynamic> data) async {
    await into(glucoseReadings).insertOnConflictUpdate(
      GlucoseReadingsCompanion(
        id: Value(id),
        valueMgDl: Value((data['valueMgDl'] as num).toDouble()),
        measuredAt: Value(DateTime.parse(data['measuredAt'] as String)),
        source: Value(
          GlucoseSource.values.firstWhere(
            (e) => e.name == data['source'],
            orElse: () => GlucoseSource.manual,
          ),
        ),
        externalId: Value(data['externalId'] as String?),
        mealContext: Value(
          data['mealContext'] != null
              ? MealContext.values.firstWhere(
                  (e) => e.name == data['mealContext'],
                  orElse: () => MealContext.other,
                )
              : null,
        ),
        notes: Value(data['notes'] as String?),
        syncStatus: const Value(SyncStatus.synced),
        lastModifiedAt: Value(DateTime.parse(data['lastModifiedAt'] as String)),
        createdAt: Value(DateTime.parse(data['createdAt'] as String)),
      ),
    );
  }
}
