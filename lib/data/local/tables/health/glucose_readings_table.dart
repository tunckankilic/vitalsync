/// VitalSync — Glucose Readings Table (Health Module).
library;

import 'package:drift/drift.dart';

import '../../../../core/enums/glucose_source.dart';
import '../../../../core/enums/meal_context.dart';
import '../../../../core/enums/sync_status.dart';

/// Blood glucose readings, imported from Apple Health or entered manually.
///
/// The table stores measurements only. It carries no reference range, no
/// rating and no derived score — interpretation is deliberately out of scope.
@DataClassName('GlucoseReadingData')
@TableIndex(
  name: 'idx_glucose_readings_external_id',
  columns: {#externalId},
  unique: true,
)
class GlucoseReadings extends Table {
  /// Primary key.
  IntColumn get id => integer().autoIncrement()();

  /// Measured value in the canonical unit mg/dL.
  /// Readings arriving in mmol/L are converted before they reach this table.
  RealColumn get valueMgDl => real()();

  /// When the reading was taken.
  DateTimeColumn get measuredAt => dateTime()();

  /// Where the reading came from (Apple Health or manual entry).
  TextColumn get source => textEnum<GlucoseSource>()();

  /// External store identifier (HealthKit sample UUID).
  /// Null for manual entries. Unique so re-imports do not duplicate rows.
  TextColumn get externalId => text().nullable()();

  /// Optional label for when the reading was taken relative to a meal.
  TextColumn get mealContext => textEnum<MealContext>().nullable()();

  /// Free-form user note about the reading.
  TextColumn get notes => text().nullable()();

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
