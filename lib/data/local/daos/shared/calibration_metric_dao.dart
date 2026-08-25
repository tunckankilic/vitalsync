/// VitalSync — Calibration Metric DAO (Shared Module).
library;

import 'package:drift/drift.dart';
import 'package:vitalsync/core/enums/sync_status.dart';
import 'package:vitalsync/data/local/database.dart';

import '../../tables/shared/calibration_metrics_table.dart';
import '../remote_payload.dart';

part 'calibration_metric_dao.g.dart';

/// DAO for weekly calibration counter operations.
///
/// **Counts only, no interpretation.** Every method here reads or writes
/// tallies. No method derives a rating, a score or any statement about what
/// the numbers mean.
@DriftAccessor(tables: [CalibrationMetrics])
class CalibrationMetricDao extends DatabaseAccessor<AppDatabase>
    with _$CalibrationMetricDaoMixin {
  CalibrationMetricDao(super.db);

  /// Get all weekly metric rows, newest week first.
  Future<List<CalibrationMetricData>> getAll() {
    return (select(
      calibrationMetrics,
    )..orderBy([(tbl) => OrderingTerm.desc(tbl.weekStart)])).get();
  }

  /// Get metric rows whose week start falls in a date range, newest first.
  Future<List<CalibrationMetricData>> getByDateRange(
    DateTime start,
    DateTime end,
  ) {
    return (select(calibrationMetrics)
          ..where(
            (tbl) =>
                tbl.weekStart.isBiggerOrEqualValue(start) &
                tbl.weekStart.isSmallerOrEqualValue(end),
          )
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.weekStart)]))
        .get();
  }

  /// Returns a single metric row by ID, or null if not found.
  Future<CalibrationMetricData?> getById(int id) {
    return (select(
      calibrationMetrics,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Returns the metric row for a given week start, or null if not found.
  Future<CalibrationMetricData?> getByWeekStart(DateTime weekStart) {
    return (select(
      calibrationMetrics,
    )..where((tbl) => tbl.weekStart.equals(weekStart))).getSingleOrNull();
  }

  /// Insert a new weekly metric row.
  Future<int> insert(CalibrationMetricsCompanion metric) {
    return into(calibrationMetrics).insert(metric);
  }

  /// Update an existing weekly metric row.
  Future<bool> updateMetric(CalibrationMetricData metric) {
    return update(calibrationMetrics).replace(metric);
  }

  /// Delete a weekly metric row by ID.
  Future<int> deleteMetric(int id) {
    return (delete(calibrationMetrics)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Watch recent weekly metric rows.
  Stream<List<CalibrationMetricData>> watchRecent({int limit = 20}) {
    return (select(calibrationMetrics)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.weekStart)])
          ..limit(limit))
        .watch();
  }

  /// Inserts or updates a weekly metric row from cloud remote data.
  /// Sets [syncStatus] to [SyncStatus.synced] to prevent re-pushing.
  /// Does NOT trigger sync queue insertion.
  Future<void> upsertFromRemote(int id, Map<String, dynamic> data) async {
    await into(calibrationMetrics).insertOnConflictUpdate(
      CalibrationMetricsCompanion(
        id: Value(id),
        weekStart: Value(DateTime.parse(data['weekStart'] as String)),
        mealsLogged: Value(data['mealsLogged'] as int? ?? 0),
        glucoseReadings: Value(data['glucoseReadings'] as int? ?? 0),
        manualReadings: Value(data['manualReadings'] as int? ?? 0),
        coveredMeals: Value(data['coveredMeals'] as int? ?? 0),
        uncoveredReasons: Value(
          encodeJsonColumn(data['uncoveredReasons'], fallback: '{}'),
        ),
        appVersion: Value(data['appVersion'] as String? ?? ''),
        syncStatus: const Value(SyncStatus.synced),
        lastModifiedAt: Value(DateTime.parse(data['lastModifiedAt'] as String)),
        createdAt: Value(DateTime.parse(data['createdAt'] as String)),
      ),
    );
  }
}
