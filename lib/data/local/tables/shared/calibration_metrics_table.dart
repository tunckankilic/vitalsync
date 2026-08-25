/// VitalSync — Calibration Metrics Table (Shared Module).
library;

import 'package:drift/drift.dart';

import '../../../../core/enums/sync_status.dart';

/// Weekly opt-in calibration counters.
///
/// **Counts only, no interpretation.** Every column here is a tally of how
/// much data was recorded in a given week. No column expresses a judgement
/// about the data, and nothing derived from glucose values themselves is
/// stored. Rows are written only while the user has granted the separate
/// calibration telemetry consent.
@DataClassName('CalibrationMetricData')
class CalibrationMetrics extends Table {
  /// Primary key.
  IntColumn get id => integer().autoIncrement()();

  /// Monday 00:00 of the week these counters cover.
  DateTimeColumn get weekStart => dateTime()();

  /// How many meals were logged during the week.
  IntColumn get mealsLogged => integer()();

  /// How many glucose readings exist for the week, from any source.
  IntColumn get glucoseReadings => integer()();

  /// How many of those readings were entered manually.
  IntColumn get manualReadings => integer()();

  /// How many logged meals had glucose readings around them.
  IntColumn get coveredMeals => integer()();

  /// JSON counter map of why meals were not covered.
  /// Example: {"noReadingBefore": 3, "noReadingAfter": 1}
  TextColumn get uncoveredReasons => text()();

  /// App version that produced the row, so counters stay comparable
  /// across releases.
  TextColumn get appVersion => text()();

  /// Sync status for offline-first architecture.
  /// Stored as string, converted to/from SyncStatus enum.
  TextColumn get syncStatus =>
      textEnum<SyncStatus>().withDefault(const Constant('synced'))();

  /// Last modification timestamp for conflict resolution.
  DateTimeColumn get lastModifiedAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
