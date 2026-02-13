/// VitalSync — Symptoms Table (Health Module).
library;

import 'package:drift/drift.dart';

import '../../../../core/enums/sync_status.dart';

/// Symptoms table for tracking user-reported health symptoms.
///
/// Allows users to log symptoms with severity ratings and tags.
/// Used for health timeline and cross-module insights
/// (e.g., correlating symptoms with workouts or medication adherence).
@DataClassName('SymptomData')
class Symptoms extends Table {
  /// Primary key.
  IntColumn get id => integer().autoIncrement()();

  /// Symptom name (e.g., "Headache", "Fatigue", "Nausea").
  /// Can be free-form or selected from predefined common symptoms.
  TextColumn get name => text()();

  /// Severity rating on a scale of 1-5.
  /// 1 = Mild, 5 = Severe
  IntColumn get severity => integer()();

  /// When the symptom was experienced.
  DateTimeColumn get date => dateTime()();

  /// Additional notes about the symptom.
  /// Can include context like "After workout" or "Before medication".
  TextColumn get notes => text().nullable()();

  /// JSON array of tags for categorization.
  /// Example: ["chronic", "after_exercise", "morning"]
  TextColumn get tags => text()();

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
