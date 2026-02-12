/// VitalSync — Medications Table (Health Module).
library;

import 'package:drift/drift.dart';

import '../../../../core/enums/medication_frequency.dart';
import '../../../../core/enums/sync_status.dart';

/// Medications table for tracking user's prescriptions and supplements.
///
/// Stores medication details including dosage, schedule, and sync status
/// for offline-first architecture.
@DataClassName('MedicationData')
class Medications extends Table {
  /// Primary key.
  IntColumn get id => integer().autoIncrement()();

  /// Medication name (e.g., "Aspirin", "Metformin").
  TextColumn get name => text()();

  /// Dosage information (e.g., "500mg", "1 tablet").
  TextColumn get dosage => text()();

  /// How often the medication should be taken.
  /// Stored as string, converted to/from MedicationFrequency enum.
  TextColumn get frequency => textEnum<MedicationFrequency>()();

  /// JSON array of scheduled times (e.g., ["08:00", "20:00"]).
  /// Format: 24-hour time strings.
  TextColumn get times => text()();

  /// When the medication regimen started.
  DateTimeColumn get startDate => dateTime()();

  /// When the medication regimen ends (nullable for ongoing medications).
  DateTimeColumn get endDate => dateTime().nullable()();

  /// Additional notes about the medication.
  TextColumn get notes => text().nullable()();

  /// UI color for this medication (stored as integer/ARGB value).
  /// Used for visual differentiation in the UI.
  IntColumn get color => integer()();

  /// Whether this medication is currently active.
  /// Inactive medications won't generate reminders.
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Sync status for offline-first architecture.
  /// Stored as string, converted to/from SyncStatus enum.
  TextColumn get syncStatus =>
      textEnum<SyncStatus>().withDefault(const Constant('synced'))();

  /// Last modification timestamp for conflict resolution.
  /// Used when syncing with Firestore to determine which version is newer.
  DateTimeColumn get lastModifiedAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Last update timestamp.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
