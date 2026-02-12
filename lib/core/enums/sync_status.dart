/// VitalSync — Sync Status Enum.
///
/// Tracks the synchronization status for offline-first architecture.
/// Used across health, fitness, and other syncable tables.
library;

/// Synchronization status for offline-first data model.
///
/// - [synced]: Data is in sync with Firestore
/// - [pending]: Local changes waiting to be synced
/// - [conflict]: Sync conflict detected, needs resolution
enum SyncStatus {
  synced,
  pending,
  conflict;

  /// Convert to string for database storage.
  String toDbValue() => name;

  /// Create from database string value.
  static SyncStatus fromDbValue(String value) {
    return SyncStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SyncStatus.pending,
    );
  }
}
