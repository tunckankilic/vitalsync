/// VitalSync — Sync Queue Table (Shared).
/// Manages offline-first sync queue for Firestore synchronization.
library;

import 'package:drift/drift.dart';

import 'package:vitalsync/core/enums/sync_enums.dart';

/// Sync queue table for offline-first architecture.
/// When data is modified locally while offline (or before Firestore sync),
/// entries are added to this queue. When connectivity is restored,
/// the sync service processes the queue to push changes to Firestore.
@DataClassName('SyncQueueData')
class SyncQueue extends Table {
  /// Primary key.
  IntColumn get id => integer().autoIncrement()();

  /// Name of the table that was modified.
  /// Example: 'medications', 'workout_sessions', 'symptoms'
  TextColumn get targetTable => text()();

  /// ID of the record in the source table.
  IntColumn get recordId => integer()();

  /// Type of operation performed.
  /// Stored as string, converted to/from SyncOperation enum.
  TextColumn get operation => textEnum<SyncOperation>()();

  /// JSON payload containing the full record data.
  /// This allows the sync service to reconstruct the data for Firestore.
  TextColumn get payload => text()();

  /// Current status of this sync item.
  /// Stored as string, converted to/from SyncQueueStatus enum.
  TextColumn get status =>
      textEnum<SyncQueueStatus>().withDefault(const Constant('pending'))();

  /// Number of times sync was attempted for this item.
  /// Used for exponential backoff and eventual failure handling.
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  /// When this sync item was created (queued).
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// When the last sync attempt was made (nullable).
  /// Null if never attempted yet.
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
}
