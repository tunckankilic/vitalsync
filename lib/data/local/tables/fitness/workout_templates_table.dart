/// VitalSync — Workout Templates Table (Fitness Module).
library;

import 'package:drift/drift.dart';

/// Workout templates table for pre-defined workout routines.
///
/// Templates serve as blueprints for workouts. Users can create sessions
/// from templates or create custom workouts from scratch.
@DataClassName('WorkoutTemplateData')
class WorkoutTemplates extends Table {
  /// Primary key.
  IntColumn get id => integer().autoIncrement()();

  /// Template name (e.g., "Push Day", "Full Body", "Leg Day").
  TextColumn get name => text()();

  /// Description of the template (nullable).
  /// Can include training goals, difficulty level, etc.
  TextColumn get description => text().nullable()();

  /// UI color for this template (stored as integer/ARGB value).
  /// Used for visual differentiation in the UI.
  IntColumn get color => integer()();

  /// Estimated duration in minutes.
  /// Helps users plan their training.
  IntColumn get estimatedDuration => integer()();

  /// Whether this is a default app-provided template.
  /// False for user-created templates.
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Last update timestamp.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
