/// VitalSync — Health Samples Table (Health Module).
library;

import 'package:drift/drift.dart';

import '../../../../core/enums/health_data_source_kind.dart';
import '../../../../core/enums/health_sample_type.dart';

/// Generic container for imported activity and sleep samples
/// (steps, active energy, workouts, sleep).
///
/// This table has **no** `syncStatus` column on purpose: the samples are a
/// local mirror of the platform health store, which is itself the source of
/// truth and is restored by the OS on a new device. Pushing them to the cloud
/// would duplicate that data without adding durability.
@DataClassName('HealthSampleData')
@TableIndex(
  name: 'idx_health_samples_external_id',
  columns: {#externalId},
  unique: true,
)
class HealthSamples extends Table {
  /// Primary key.
  IntColumn get id => integer().autoIncrement()();

  /// Which of the four supported sample types this row holds.
  TextColumn get type => textEnum<HealthSampleType>()();

  /// Start of the sample interval.
  DateTimeColumn get startAt => dateTime()();

  /// End of the sample interval.
  /// Null for instantaneous samples.
  DateTimeColumn get endAt => dateTime().nullable()();

  /// Measured value, expressed in [unit].
  RealColumn get value => real()();

  /// Unit of [value] (e.g. "count", "kcal", "min").
  TextColumn get unit => text()();

  /// Which store the sample was read from.
  TextColumn get source => textEnum<HealthDataSourceKind>()();

  /// External store identifier (HealthKit sample UUID).
  /// Unique so repeated imports do not duplicate rows.
  TextColumn get externalId => text().nullable()();

  /// JSON object with type-specific extras (e.g. workout activity name).
  TextColumn get metadata => text().nullable()();

  /// Last modification timestamp.
  DateTimeColumn get lastModifiedAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
