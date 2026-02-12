/// VitalSync — Template Exercises Table (Fitness Module).
library;

import 'package:drift/drift.dart';

import 'exercises_table.dart';
import 'workout_templates_table.dart';

/// Template exercises table - junction table linking templates to exercises.
///
/// Defines which exercises are in each template and their default parameters
/// (sets, reps, weight, rest periods). Users can modify these when starting
/// a workout session.
@DataClassName('TemplateExerciseData')
class TemplateExercises extends Table {
  /// Primary key.
  IntColumn get id => integer().autoIncrement()();

  /// Foreign key to the workout templates table.
  IntColumn get templateId => integer().references(WorkoutTemplates, #id)();

  /// Foreign key to the exercises table.
  IntColumn get exerciseId => integer().references(Exercises, #id)();

  /// Order of this exercise in the template (0-indexed).
  /// Determines the sequence exercises appear in the workout.
  IntColumn get orderIndex => integer()();

  /// Default number of sets for this exercise in the template.
  IntColumn get defaultSets => integer()();

  /// Default number of reps per set.
  IntColumn get defaultReps => integer()();

  /// Default weight (nullable, for bodyweight exercises or when unspecified).
  /// Stored in kg (convert to lbs in UI if user prefers imperial).
  RealColumn get defaultWeight => real().nullable()();

  /// Rest time between sets in seconds.
  IntColumn get restSeconds => integer()();
}
