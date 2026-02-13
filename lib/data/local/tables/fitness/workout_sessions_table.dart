/// VitalSync — Workout Sessions Table (Fitness Module).
library;

import 'package:drift/drift.dart';

import '../../../../core/enums/sync_status.dart';
import '../../../../core/enums/workout_rating.dart';
import 'workout_templates_table.dart';

/// Workout sessions table for tracking actual workout instances.
///
/// Each session represents a workout that was started (and optionally completed).
/// Sessions can be based on templates or created from scratch.
@DataClassName('WorkoutSessionData')
class WorkoutSessions extends Table {
  /// Primary key.
  IntColumn get id => integer().autoIncrement()();

  /// Foreign key to the workout templates table (nullable).
  /// Null if this is a custom workout not based on a template.
  IntColumn get templateId =>
      integer().references(WorkoutTemplates, #id).nullable()();

  /// Session name (e.g., "Morning Push Day", "Leg Day").
  /// Defaults to template name if based on a template.
  TextColumn get name => text()();

  /// When the workout session started.
  DateTimeColumn get startTime => dateTime()();

  /// When the workout session ended (nullable if still in progress).
  DateTimeColumn get endTime => dateTime().nullable()();

  /// Total volume lifted during this session (sum of all sets: reps × weight).
  /// Calculated and stored in kg.
  RealColumn get totalVolume => real()();

  /// Optional notes about the session.
  /// Can include feelings, environment, modifications made, etc.
  TextColumn get notes => text().nullable()();

  /// User rating of the workout (1-5, nullable).
  /// 1 = Terrible, 5 = Amazing
  IntColumn get rating => intEnum<WorkoutRating>().nullable()();

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
