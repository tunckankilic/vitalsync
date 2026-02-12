/// VitalSync — Medication Logs Table (Health Module).
library;

import 'package:drift/drift.dart';

import '../../../../core/enums/medication_log_status.dart';
import '../../../../core/enums/sync_status.dart';
import 'medications_table.dart';

/// Medication logs table for tracking medication adherence.
///
/// Each log represents a scheduled medication dose and whether it was
/// taken, skipped, or missed. Used for compliance calculations and insights.
@DataClassName('MedicationLogData')
class MedicationLogs extends Table {
  /// Primary key.
  IntColumn get id => integer().autoIncrement()();

  /// Foreign key to the medications table.
  /// References which medication this log is for.
  IntColumn get medicationId => integer().references(Medications, #id)();

  /// When this dose was scheduled to be taken.
  DateTimeColumn get scheduledTime => dateTime()();

  /// When the dose was actually taken (nullable if not taken yet or skipped).
  DateTimeColumn get takenTime => dateTime().nullable()();

  /// Status of this medication log entry.
  /// Stored as string, converted to/from MedicationLogStatus enum.
  TextColumn get status =>
      textEnum<MedicationLogStatus>().withDefault(const Constant('pending'))();

  /// Optional notes about this dose (e.g., "Took with food", "Side effects").
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
