/// VitalSync — Drift ↔ Firestore Sync Service.
/// Offline-first architecture: Drift is primary, Firestore is backup.
/// Processes sync queue when connectivity is available.
/// Handles conflict resolution via lastModifiedAt timestamps.
library;

import 'dart:convert';
import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/enums/sync_enums.dart';
import '../../data/local/database.dart';
import '../network/connectivity_service.dart';

/// Sync Service for VitalSync.
/// Manages synchronization between local Drift database (primary)
/// and Firestore cloud backup. Uses an offline-first approach where
/// all writes go to Drift first, then sync to Firestore when connected.
class SyncService {
  SyncService({
    required AppDatabase database,
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required ConnectivityService connectivity,
  }) : _database = database,
       _firestore = firestore,
       _auth = auth,
       _connectivity = connectivity;
  final AppDatabase _database;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final ConnectivityService _connectivity;

  bool _isSyncing = false;

  /// Triggers a manual sync operation.
  /// Syncs pending local changes to Firestore and pulls any
  /// remote changes that are newer than local data.
  /// Converts a Firestore document map to local database format.
  /// - Firestore [Timestamp] → ISO 8601 String
  /// - Firestore [GeoPoint] → lat/lng map (if used)
  /// - Handles nested maps recursively
  Map<String, dynamic> _convertFromFirestoreFormat(Map<String, dynamic> data) {
    final result = <String, dynamic>{};

    for (final entry in data.entries) {
      final value = entry.value;

      if (value == null) {
        result[entry.key] = null;
      } else if (value is Timestamp) {
        // Firestore Timestamp → ISO 8601 string for Drift
        result[entry.key] = value.toDate().toIso8601String();
      } else if (value is Map<String, dynamic>) {
        result[entry.key] = _convertFromFirestoreFormat(value);
      } else if (value is List) {
        result[entry.key] = value.map((item) {
          if (item is Timestamp) return item.toDate().toIso8601String();
          if (item is Map<String, dynamic>) {
            return _convertFromFirestoreFormat(item);
          }
          return item;
        }).toList();
      } else {
        // int, double, bool, String → pass through
        result[entry.key] = value;
      }
    }

    return result;
  }

  Future<void> sync() async {
    // Check if already syncing
    if (_isSyncing) {
      log('Sync already in progress, skipping...');
      return;
    }

    // Check connectivity
    if (!await _connectivity.isConnected()) {
      log('No internet connection, sync skipped');
      return;
    }

    // Check authentication
    final user = _auth.currentUser;
    if (user == null) {
      log('User not authenticated, sync skipped');
      return;
    }

    _isSyncing = true;

    try {
      // TODO: Implement full sync logic in Prompt 2.x
      // This is a placeholder implementation
      log('Starting sync for user: ${user.uid}');

      // Step 1: Push pending local changes to Firestore
      await _pushPendingChanges(user.uid);

      // Step 2: Pull remote changes from Firestore
      await _pullRemoteChanges(user.uid);

      log('Sync completed successfully');
    } catch (e) {
      log('Sync failed: $e');
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  /// Pushes pending local changes to Firestore.
  /// Processes the sync queue and uploads modified records.
  Future<void> _pushPendingChanges(String uid) async {
    log('Starting push of pending changes...');

    // Get all pending sync items from the queue
    final pendingItems = await _database.syncDao.getPendingItems();

    if (pendingItems.isEmpty) {
      log('No pending changes to push');
      return;
    }

    log('Found ${pendingItems.length} pending items to sync');

    // Process each pending item
    for (final item in pendingItems) {
      try {
        // Mark as in progress
        await _database.syncDao.markInProgress(item.id);

        // Get the Firestore collection reference for this user
        final collectionRef = _firestore
            .collection('users')
            .doc(uid)
            .collection(item.targetTable);

        // Parse the payload
        final payload = jsonDecode(item.payload) as Map<String, dynamic>;

        // Handle different operations
        switch (item.operation) {
          case SyncOperation.insert:
          case SyncOperation.update:
            // For insert/update, check if document exists in Firestore
            final docRef = collectionRef.doc(item.recordId.toString());
            final docSnapshot = await docRef.get();

            if (docSnapshot.exists) {
              // Document exists - check for conflicts
              final remoteData = docSnapshot.data();
              final remoteModifiedAt =
                  remoteData?['lastModifiedAt'] as Timestamp?;
              final localModifiedAt = payload['lastModifiedAt'] as String?;

              if (remoteModifiedAt != null && localModifiedAt != null) {
                final remoteDate = remoteModifiedAt.toDate();
                final localDate = DateTime.parse(localModifiedAt);

                // If remote is newer, skip this update (remote wins)
                if (remoteDate.isAfter(localDate)) {
                  log(
                    'Conflict detected for ${item.targetTable}:${item.recordId} - remote is newer, skipping push',
                  );
                  await _database.syncDao.markCompleted(item.id);
                  continue;
                }
              }
            }

            // Convert DateTime strings to Firestore Timestamps
            final firestorePayload = _convertFromFirestoreFormat(payload);

            // Upload to Firestore
            await docRef.set(firestorePayload, SetOptions(merge: true));
            log(
              'Pushed ${item.operation.name} for ${item.targetTable}:${item.recordId}',
            );

          case SyncOperation.delete:
            // Delete from Firestore
            await collectionRef.doc(item.recordId.toString()).delete();
            log('Pushed delete for ${item.targetTable}:${item.recordId}');
        }

        // Mark as completed
        await _database.syncDao.markCompleted(item.id);
      } catch (e) {
        log('Failed to push ${item.targetTable}:${item.recordId}: $e');

        // Mark as failed and increment retry count
        await _database.syncDao.markFailed(item.id, item.retryCount);

        // If retry count exceeds threshold, log error but continue
        if (item.retryCount >= 3) {
          log('Item ${item.id} exceeded max retries, will retry on next sync');
        }
      }
    }

    log('Finished pushing pending changes');
  }

  /// Pulls remote changes from Firestore.
  /// Downloads records that are newer than local copies.
  Future<void> _pullRemoteChanges(String uid) async {
    log('Starting pull of remote changes...');

    final tablesToSync = [
      'medications',
      'medication_logs',
      'symptoms',
      'workout_sessions',
    ];

    for (final tableName in tablesToSync) {
      try {
        log('Pulling $tableName from Firestore...');

        final collectionRef = _firestore
            .collection('users')
            .doc(uid)
            .collection(tableName);

        final snapshot = await collectionRef.get();

        if (snapshot.docs.isEmpty) {
          log('No remote data for $tableName');
          continue;
        }

        log('Found ${snapshot.docs.length} remote records for $tableName');

        for (final doc in snapshot.docs) {
          try {
            final remoteData = doc.data();
            final recordId = int.tryParse(doc.id);

            if (recordId == null) {
              log('Invalid document ID: ${doc.id}');
              continue;
            }

            // Convert Firestore format → local format
            final localData = _convertFromFirestoreFormat(remoteData);

            // Get local record's lastModifiedAt for comparison
            final localModifiedAt = await _getLocalModifiedAt(
              tableName,
              recordId,
            );

            final remoteModifiedAt = remoteData['lastModifiedAt'] as Timestamp?;

            if (remoteModifiedAt == null) {
              log('Remote $tableName:$recordId has no timestamp, skipping');
              continue;
            }

            final remoteDate = remoteModifiedAt.toDate();

            // If local doesn't exist or remote is newer → upsert
            if (localModifiedAt == null ||
                remoteDate.isAfter(localModifiedAt)) {
              await _upsertLocalRecord(tableName, recordId, localData);
              log('Pulled $tableName:$recordId (remote was newer)');
            } else {
              log('Skipped $tableName:$recordId (local is up to date)');
            }
          } catch (e) {
            log('Failed to process remote document ${doc.id}: $e');
          }
        }
      } catch (e) {
        log('Failed to pull $tableName: $e');
      }
    }

    log('Finished pulling remote changes');
  }

  /// Returns the local record's lastModifiedAt, or null if not found.
  Future<DateTime?> _getLocalModifiedAt(String tableName, int recordId) async {
    switch (tableName) {
      case 'medications':
        final record = await _database.medicationDao.getById(recordId);
        return record?.lastModifiedAt;
      case 'medication_logs':
        final record = await _database.medicationLogDao.getById(recordId);
        return record?.lastModifiedAt;
      case 'symptoms':
        final record = await _database.symptomDao.getById(recordId);
        return record?.lastModifiedAt;
      case 'workout_sessions':
        final record = await _database.workoutSessionDao.getById(recordId);
        return record?.lastModifiedAt;
      default:
        log('Unknown table: $tableName');
        return null;
    }
  }

  /// Inserts or updates a local record from remote data.
  /// Does NOT add to sync queue (to avoid re-pushing back to Firestore).
  Future<void> _upsertLocalRecord(
    String tableName,
    int recordId,
    Map<String, dynamic> data,
  ) async {
    switch (tableName) {
      case 'medications':
        await _database.medicationDao.upsertFromRemote(recordId, data);
      case 'medication_logs':
        await _database.medicationLogDao.upsertFromRemote(recordId, data);
      case 'symptoms':
        await _database.symptomDao.upsertFromRemote(recordId, data);
      case 'workout_sessions':
        await _database.workoutSessionDao.upsertFromRemote(recordId, data);
      default:
        log('Unknown table for upsert: $tableName');
    }
  }

  /// Performs initial sync when user first signs in.
  /// Downloads all user data from Firestore to local database.
  Future<void> initialSync() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated for initial sync');
    }

    if (!await _connectivity.isConnected()) {
      throw Exception('Internet connection required for initial sync');
    }

    log('Starting initial sync for user: ${user.uid}');

    try {
      // Pull all remote data
      await _pullRemoteChanges(user.uid);

      // Clear any pending sync items since we just did a full sync
      // This prevents duplicate uploads
      final completedCount = await _database.syncDao.deleteCompletedOlderThan(
        DateTime.now().subtract(const Duration(days: 1)),
      );

      log('Initial sync completed. Cleaned up $completedCount old sync items.');
    } catch (e) {
      log('Initial sync failed: $e');
      rethrow;
    }
  }

  /// Checks if sync is currently in progress.
  bool get isSyncing => _isSyncing;

  /// Starts automatic sync on connectivity changes.
  /// Listens to connectivity stream and triggers sync when online.
  void startAutoSync() {
    _connectivity.connectivityStream.listen((isConnected) {
      if (isConnected && !_isSyncing) {
        // Trigger sync when coming online
        sync().catchError((error) {
          log('Auto-sync failed: $error');
        });
      }
    });
  }
}
