/// VitalSync — User Stats Table (Fitness Module).
library;

import 'package:drift/drift.dart';

/// User stats table for daily aggregated statistics.
///
/// Stores daily summaries of fitness and health metrics.
/// Used for progress tracking, charts, and cross-module insights.
/// Each day has one row (unique date constraint).
@DataClassName('UserStatsData')
class UserStats extends Table {
  /// Primary key.
  IntColumn get id => integer().autoIncrement()();

  /// Date for these stats (unique - one row per day).
  /// Stores date only (time is normalized to midnight).
  DateTimeColumn get date => dateTime().unique()();

  /// Total number of workouts completed on this day.
  IntColumn get totalWorkouts => integer()();

  /// Total volume lifted on this day (sum of all workout_sessions.totalVolume).
  /// Stored in kg.
  RealColumn get totalVolume => real()();

  /// Total workout duration on this day in minutes.
  IntColumn get totalDuration => integer()();

  /// Current workout streak in days (as of this date).
  /// Updated daily based on workout activity.
  IntColumn get streakDays => integer()();

  /// Medication compliance rate for this day (0.0 - 1.0).
  /// Example: 0.75 means 75% of scheduled medications were taken.
  /// This is a cross-module metric that bridges health and fitness.
  RealColumn get medicationCompliance => real()();
}
