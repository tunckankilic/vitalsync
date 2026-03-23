/// VitalSync — Abstract Cloud Sync Client.
///
/// Defines the contract for cloud sync operations.
/// Implementations can use Firestore, REST API, or any other backend.
/// This abstraction allows swapping the cloud provider without
/// changing sync logic in SyncService.
library;

/// Represents a single sync operation result from the cloud.
class CloudSyncRecord {
  const CloudSyncRecord({
    required this.id,
    required this.data,
    required this.lastModifiedAt,
  });

  /// The record ID (document ID / item key).
  final String id;

  /// The record data as a map.
  final Map<String, dynamic> data;

  /// When this record was last modified on the cloud.
  final DateTime lastModifiedAt;
}

/// Abstract interface for cloud sync operations.
///
/// Implementations:
/// - [FirestoreSyncClient] — Current Firebase Firestore implementation
/// - [RestSyncClient] — Future AWS REST API implementation
abstract class CloudSyncClient {
  /// Pushes a single record to the cloud.
  ///
  /// [userId] — The authenticated user's ID.
  /// [collection] — The collection/table name (e.g., 'medications').
  /// [recordId] — The record's unique ID.
  /// [data] — The record data as a JSON-serializable map.
  /// [merge] — Whether to merge with existing data (true) or overwrite (false).
  ///
  /// Returns the cloud's `lastModifiedAt` timestamp for the record,
  /// or null if the cloud does not return a timestamp.
  Future<DateTime?> pushRecord({
    required String userId,
    required String collection,
    required String recordId,
    required Map<String, dynamic> data,
    bool merge = true,
  });

  /// Deletes a single record from the cloud.
  Future<void> deleteRecord({
    required String userId,
    required String collection,
    required String recordId,
  });

  /// Pulls records from a collection that were modified after [since].
  ///
  /// If [since] is null, pulls all records (full sync).
  /// Returns a list of [CloudSyncRecord]s ordered by lastModifiedAt.
  Future<List<CloudSyncRecord>> pullRecords({
    required String userId,
    required String collection,
    DateTime? since,
  });

  /// Retrieves the `lastModifiedAt` timestamp for a specific remote record.
  ///
  /// Returns null if the record does not exist on the cloud.
  Future<DateTime?> getRemoteModifiedAt({
    required String userId,
    required String collection,
    required String recordId,
  });

  /// Deletes ALL user data from the cloud (GDPR right to erasure).
  ///
  /// [collections] — List of collection names to delete.
  Future<void> deleteAllUserData({
    required String userId,
    required List<String> collections,
  });

  /// Exports all user data from the cloud as a JSON-serializable map.
  ///
  /// Used for GDPR right to data portability.
  Future<Map<String, dynamic>> exportAllUserData({
    required String userId,
    required List<String> collections,
  });
}
