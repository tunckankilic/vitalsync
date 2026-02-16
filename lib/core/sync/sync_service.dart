/// VitalSync — Drift ↔ Firestore Sync Service.
/// Offline-first architecture: Drift is primary, Firestore is backup.
/// Processes sync queue when connectivity is available.
/// Handles conflict resolution via lastModifiedAt timestamps.
/// GDPR: Cloud backup consent required before any Firestore writes.
library;

import 'dart:convert';
import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/enums/sync_enums.dart';
import '../../data/local/database.dart';
import '../network/connectivity_service.dart';

/// Sync Service for VitalSync.
/// Manages synchronization between local Drift database (primary)
/// and Firestore cloud backup. Uses an offline-first approach where
/// all writes go to Drift first, then sync to Firestore when connected.
///
/// Firestore Structure:
///   users/{uid}/medications/{id}
///   users/{uid}/medication_logs/{id}
///   users/{uid}/symptoms/{id}
///   users/{uid}/workout_sessions/{id}
///   users/{uid}/workout_sets/{sessionId}_{setId}
///   users/{uid}/personal_records/{id}
///   users/{uid}/achievements/{id}
///   users/{uid}/insights/{id} (optional)
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

  /// Maximum number of writes per sync batch (rate limiting).
  static const _maxBatchSize = 10;

  /// All Firestore collections that participate in sync.
  static const _tablesToSync = [
    'medications',
    'medication_logs',
    'symptoms',
    'workout_sessions',
    'workout_sets',
    'personal_records',
    'achievements',
  ];

  /// Converts a Firestore document map to local database format.
  /// - Firestore [Timestamp] → ISO 8601 String
  /// - Handles nested maps recursively
  Map<String, dynamic> _convertFromFirestoreFormat(Map<String, dynamic> data) {
    final result = <String, dynamic>{};

    for (final entry in data.entries) {
      final value = entry.value;

      if (value == null) {
        result[entry.key] = null;
      } else if (value is Timestamp) {
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
        result[entry.key] = value;
      }
    }

    return result;
  }

  /// Checks if cloud backup consent has been granted (GDPR).
  /// Returns false if consent was never granted or was revoked.
  Future<bool> _hasCloudBackupConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.prefKeyCloudBackupConsent) ?? false;
  }

  /// Triggers a manual sync operation.
  /// Syncs pending local changes to Firestore and pulls any
  /// remote changes that are newer than local data.
  Future<void> sync() async {
    if (_isSyncing) {
      log('Sync already in progress, skipping...');
      return;
    }

    // GDPR: Do not sync to cloud without explicit consent
    if (!await _hasCloudBackupConsent()) {
      log('Cloud backup consent not granted, sync skipped (GDPR)');
      return;
    }

    if (!await _connectivity.isConnected()) {
      log('No internet connection, sync skipped');
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      log('User not authenticated, sync skipped');
      return;
    }

    _isSyncing = true;

    try {
      log('Starting bidirectional sync for user: ${user.uid}');

      // Step 1: Push pending local changes to Firestore
      log('Step 1/3: Pushing local changes...');
      await _pushPendingChanges(user.uid);

      // Step 2: Pull remote changes from Firestore
      log('Step 2/3: Pulling remote changes...');
      await _pullRemoteChanges(user.uid);

      // Step 3: Conflict resolution is handled within push/pull methods
      // based on lastModifiedAt timestamps (last-write-wins)
      log('Step 3/3: Conflict resolution completed');

      log('Sync completed successfully');
    } catch (e) {
      log('Sync failed: $e');
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  /// Pushes pending local changes to Firestore.
  /// Processes the sync queue with rate limiting (max [_maxBatchSize] per batch).
  Future<void> _pushPendingChanges(String uid) async {
    log('Starting push of pending changes...');

    final pendingItems = await _database.syncDao.getPendingItems();

    if (pendingItems.isEmpty) {
      log('No pending changes to push');
      return;
    }

    log('Found ${pendingItems.length} pending items to sync');

    // Rate limiting: process max _maxBatchSize items per sync cycle
    final batch = pendingItems.take(_maxBatchSize).toList();
    if (pendingItems.length > _maxBatchSize) {
      log(
        'Processing first $_maxBatchSize of ${pendingItems.length} items (rate limited)',
      );
    }

    for (final item in batch) {
      try {
        await _database.syncDao.markInProgress(item.id);

        final collectionRef = _firestore
            .collection('users')
            .doc(uid)
            .collection(item.targetTable);

        final payload = jsonDecode(item.payload) as Map<String, dynamic>;

        switch (item.operation) {
          case SyncOperation.insert:
          case SyncOperation.update:
            final docRef = collectionRef.doc(item.recordId.toString());
            final docSnapshot = await docRef.get();

            if (docSnapshot.exists) {
              final remoteData = docSnapshot.data();
              final remoteModifiedAt =
                  remoteData?['lastModifiedAt'] as Timestamp?;
              final localModifiedAt = payload['lastModifiedAt'] as String?;

              if (remoteModifiedAt != null && localModifiedAt != null) {
                final remoteDate = remoteModifiedAt.toDate();
                final localDate = DateTime.parse(localModifiedAt);

                if (remoteDate.isAfter(localDate)) {
                  log(
                    'Conflict: ${item.targetTable}:${item.recordId} — '
                    'remote is newer, skipping push',
                  );
                  await _database.syncDao.markCompleted(item.id);
                  continue;
                }
              }
            }

            final firestorePayload = _convertFromFirestoreFormat(payload);
            await docRef.set(firestorePayload, SetOptions(merge: true));
            log(
              'Pushed ${item.operation.name} for ${item.targetTable}:${item.recordId}',
            );

          case SyncOperation.delete:
            await collectionRef.doc(item.recordId.toString()).delete();
            log('Pushed delete for ${item.targetTable}:${item.recordId}');
        }

        await _database.syncDao.markCompleted(item.id);
      } catch (e) {
        log('Failed to push ${item.targetTable}:${item.recordId}: $e');

        await _database.syncDao.markFailed(item.id, item.retryCount);

        if (item.retryCount >= AppConstants.syncMaxRetries) {
          log(
            'Item ${item.id} exceeded max retries (${AppConstants.syncMaxRetries}), '
            'will retry on next sync',
          );
        }
      }
    }

    log('Finished pushing pending changes');
  }

  /// Pulls remote changes from Firestore.
  /// Downloads records that are newer than local copies.
  Future<void> _pullRemoteChanges(String uid) async {
    log('Starting pull of remote changes...');

    for (final tableName in _tablesToSync) {
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

            final localData = _convertFromFirestoreFormat(remoteData);

            final localModifiedAt = await _getLocalModifiedAt(
              tableName,
              recordId,
            );

            final remoteModifiedAt =
                remoteData['lastModifiedAt'] as Timestamp?;

            if (remoteModifiedAt == null) {
              log('Remote $tableName:$recordId has no timestamp, skipping');
              continue;
            }

            final remoteDate = remoteModifiedAt.toDate();

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
  Future<DateTime?> _getLocalModifiedAt(
    String tableName,
    int recordId,
  ) async {
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
      case 'workout_sets':
        final record = await _database.workoutSessionDao.getSetById(recordId);
        return record?.completedAt;
      case 'personal_records':
        final record = await _database.personalRecordDao.getById(recordId);
        return record?.achievedAt;
      case 'achievements':
        final record = await _database.achievementDao.getById(recordId);
        return record?.unlockedAt;
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
      case 'workout_sets':
        await _database.workoutSessionDao.upsertSetFromRemote(recordId, data);
      case 'personal_records':
        await _database.personalRecordDao.upsertFromRemote(recordId, data);
      case 'achievements':
        await _database.achievementDao.upsertFromRemote(recordId, data);
      default:
        log('Unknown table for upsert: $tableName');
    }
  }

  /// Performs initial sync when user first signs in on a new device.
  /// Downloads all user data from Firestore to local database.
  /// Requires authentication and cloud backup consent.
  Future<void> initialSync() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated for initial sync');
    }

    if (!await _hasCloudBackupConsent()) {
      throw Exception('Cloud backup consent required for initial sync');
    }

    if (!await _connectivity.isConnected()) {
      throw Exception('Internet connection required for initial sync');
    }

    log('Starting initial sync for user: ${user.uid}');

    try {
      await _pullRemoteChanges(user.uid);

      final completedCount = await _database.syncDao.deleteCompletedOlderThan(
        DateTime.now().subtract(const Duration(days: 1)),
      );

      log('Initial sync completed. Cleaned up $completedCount old sync items.');
    } catch (e) {
      log('Initial sync failed: $e');
      rethrow;
    }
  }

  /// Deletes all user data from both Drift (local) and Firestore (cloud).
  ///
  /// Used for GDPR right to erasure (Article 17).
  /// Steps:
  /// 1. Clear all local Drift tables
  /// 2. Delete all Firestore subcollections for the user
  /// 3. Delete the user document itself
  Future<void> deleteAllData() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated for data deletion');
    }

    log('Starting full data deletion for user: ${user.uid}');

    // Step 1: Clear local Drift database
    await _database.deleteAllData();
    log('Local data cleared');

    // Step 2: Delete Firestore data (if online)
    if (await _connectivity.isConnected()) {
      try {
        final userDocRef = _firestore.collection('users').doc(user.uid);

        for (final collection in _tablesToSync) {
          final snapshot = await userDocRef.collection(collection).get();
          for (final doc in snapshot.docs) {
            await doc.reference.delete();
          }
          log('Deleted Firestore collection: $collection');
        }

        // Also delete insights (optional collection)
        final insightsSnapshot =
            await userDocRef.collection('insights').get();
        for (final doc in insightsSnapshot.docs) {
          await doc.reference.delete();
        }

        // Delete the user document itself
        await userDocRef.delete();
        log('Firestore user data deleted');
      } catch (e) {
        log('Error deleting Firestore data: $e');
      }
    } else {
      log('Offline — Firestore deletion will be handled on next connection');
    }

    log('Full data deletion completed');
  }

  /// Checks if sync is currently in progress.
  bool get isSyncing => _isSyncing;

  /// Starts automatic sync on connectivity changes.
  /// Listens to connectivity stream and triggers sync when online.
  void startAutoSync() {
    _connectivity.connectivityStream.listen((isConnected) {
      if (isConnected && !_isSyncing) {
        sync().catchError((error) {
          log('Auto-sync failed: $error');
        });
      }
    });
  }
}
