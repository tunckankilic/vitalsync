/// VitalSync — Exercises Table (Fitness Module).
library;

import 'package:drift/drift.dart';

import '../../../../core/enums/equipment.dart';
import '../../../../core/enums/exercise_category.dart';

/// Exercises table containing the exercise catalog.
///
/// Includes both default exercises (provided by the app) and custom
/// exercises created by users. Used as reference data for workouts.
@DataClassName('ExerciseData')
class Exercises extends Table {
  /// Primary key.
  IntColumn get id => integer().autoIncrement()();

  /// Exercise name (e.g., "Bench Press", "Squat").
  /// International standard names (no localization on exercise names).
  TextColumn get name => text()();

  /// Primary muscle group category.
  /// Stored as string, converted to/from ExerciseCategory enum.
  TextColumn get category => textEnum<ExerciseCategory>()();

  /// Specific muscle group (e.g., "Pectorals", "Quadriceps").
  /// More detailed than category.
  TextColumn get muscleGroup => text()();

  /// Equipment required for the exercise.
  /// Stored as string, converted to/from Equipment enum.
  TextColumn get equipment => textEnum<Equipment>()();

  /// Instructions on how to perform the exercise (nullable).
  /// Can include form cues, safety notes, etc.
  TextColumn get instructions => text().nullable()();

  /// Whether this is a custom user-created exercise.
  /// False for default app-provided exercises.
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
