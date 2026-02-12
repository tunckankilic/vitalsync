/// VitalSync — Personal Records Table (Fitness Module).
library;

import 'package:drift/drift.dart';

import 'exercises_table.dart';

/// Personal records table for tracking best performances per exercise.
///
/// Stores the best weight × reps combination for each exercise.
/// Used to track progress and motivate users.
@DataClassName('PersonalRecordData')
class PersonalRecords extends Table {
  /// Primary key.
  IntColumn get id => integer().autoIncrement()();

  /// Foreign key to the exercises table.
  /// Each exercise can have one current PR.
  IntColumn get exerciseId => integer().references(Exercises, #id)();

  /// Weight used for this PR in kg.
  RealColumn get weight => real()();

  /// Number of reps completed at this weight.
  IntColumn get reps => integer()();

  /// Estimated 1 rep max calculated using Brzycki formula.
  /// Formula: weight / (1.0278 - 0.0278 × reps)
  /// This allows comparison across different rep ranges.
  RealColumn get estimated1RM => real()();

  /// When this personal record was achieved.
  DateTimeColumn get achievedAt => dateTime()();
}
