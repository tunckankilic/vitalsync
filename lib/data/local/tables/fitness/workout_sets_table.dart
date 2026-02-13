/// VitalSync — Workout Sets Table (Fitness Module).
library;

import 'package:drift/drift.dart';

import 'exercises_table.dart';
import 'workout_sessions_table.dart';

/// Workout sets table for tracking individual sets within a session.
///
/// Each row represents one set of an exercise performed during a workout.
/// This is the most granular level of workout data.
@DataClassName('WorkoutSetData')
class WorkoutSets extends Table {
  /// Primary key.
  IntColumn get id => integer().autoIncrement()();

  /// Foreign key to the workout sessions table.
  IntColumn get sessionId => integer().references(WorkoutSessions, #id)();

  /// Foreign key to the exercises table.
  IntColumn get exerciseId => integer().references(Exercises, #id)();

  /// Set number within this exercise (1-indexed).
  /// For example, if doing 3 sets of bench press, this would be 1, 2, or 3.
  IntColumn get setNumber => integer()();

  /// Number of repetitions completed.
  IntColumn get reps => integer()();

  /// Weight used for this set in kg.
  /// For bodyweight exercises, this can be 0 or the user's body weight.
  RealColumn get weight => real()();

  /// Whether this is a warmup set.
  /// Warmup sets are typically excluded from PR calculations.
  BoolColumn get isWarmup => boolean().withDefault(const Constant(false))();

  /// Whether this set achieved a new personal record.
  /// Automatically marked when PR is detected.
  BoolColumn get isPR => boolean().withDefault(const Constant(false))();

  /// When this set was completed.
  DateTimeColumn get completedAt =>
      dateTime().withDefault(currentDateAndTime)();
}
