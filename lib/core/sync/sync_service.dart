/// VitalSync — Drift ↔ Cloud Sync Service.
/// Offline-first architecture: Drift is primary, cloud is backup.
/// Processes sync queue when connectivity is available.
/// Handles conflict resolution via lastModifiedAt timestamps.
/// GDPR: Cloud backup consent required before any cloud writes.
///
/// Cloud provider is abstracted via [CloudSyncClient] interface.
/// Current implementation uses Firestore; will be swapped to REST API
/// after AWS migration.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:developer' show log;

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/enums/sync_enums.dart';
import '../../data/local/database.dart';
import '../../domain/repositories/shared/auth_repository.dart';
import '../network/connectivity_service.dart';
import 'cloud_sync_client.dart';

/// Sync Service for VitalSync.
/// Manages synchronization between local Drift database (primary)
/// and cloud backup. Uses an offline-first approach where
/// all writes go to Drift first, then sync to cloud when connected.
///
/// Cloud Structure (via CloudSyncClient):
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
    required CloudSyncClient cloudClient,
    required AuthRepository auth,
    required ConnectivityService connectivity,
  }) : _database = database,
       _cloudClient = cloudClient,
       _auth = auth,
       _connectivity = connectivity;
  final AppDatabase _database;
  final CloudSyncClient _cloudClient;
  final AuthRepository _auth;
  final ConnectivityService _connectivity;

  bool _isSyncing = false;
  StreamSubscription<bool>? _autoSyncSubscription;

  /// Maximum number of writes per sync batch (rate limiting).
  static const _maxBatchSize = 10;

  /// All cloud collections that participate in sync.
  static const tablesToSync = [
    'medications',
    'medication_logs',
    'symptoms',
    'workout_sessions',
    'workout_sets',
    'personal_records',
    'achievements',
  ];

  /// Checks if cloud backup consent has been granted (GDPR).
  /// Returns false if consent was never granted or was revoked.
  Future<bool> _hasCloudBackupConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.prefKeyCloudBackupConsent) ?? false;
  }

  /// Triggers a manual sync operation.
  /// Syncs pending local changes to cloud and pulls any
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
      log('Starting bidirectional sync for user: ${user.id}');

      // Step 1: Push pending local changes to cloud
      log('Step 1/3: Pushing local changes...');
      await _pushPendingChanges(user.id);

      // Step 2: Pull remote changes from cloud
      log('Step 2/3: Pulling remote changes...');
      await _pullRemoteChanges(user.id);

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

  /// Pushes pending local changes to the cloud.
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

        final payload = jsonDecode(item.payload) as Map<String, dynamic>;

        switch (item.operation) {
          case SyncOperation.insert:
          case SyncOperation.update:
            // Check for conflict: is remote newer?
            final remoteModifiedAt = await _cloudClient.getRemoteModifiedAt(
              userId: uid,
              collection: item.targetTable,
              recordId: item.recordId.toString(),
            );

            final localModifiedAt = payload['lastModifiedAt'] as String?;

            if (remoteModifiedAt != null && localModifiedAt != null) {
              final localDate = DateTime.parse(localModifiedAt);

              if (remoteModifiedAt.isAfter(localDate)) {
                log(
                  'Conflict: ${item.targetTable}:${item.recordId} — '
                  'remote is newer, skipping push',
                );
                await _database.syncDao.markCompleted(item.id);
                continue;
              }
            }

            await _cloudClient.pushRecord(
              userId: uid,
              collection: item.targetTable,
              recordId: item.recordId.toString(),
              data: payload,
            );
            log(
              'Pushed ${item.operation.name} for ${item.targetTable}:${item.recordId}',
            );

          case SyncOperation.delete:
            await _cloudClient.deleteRecord(
              userId: uid,
              collection: item.targetTable,
              recordId: item.recordId.toString(),
            );
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

  /// Key prefix for persisting per-table last-synced timestamps.
  static const _lastSyncPrefix = 'vitalsync_last_sync_';

  /// Pulls remote changes from cloud **incrementally**.
  ///
  /// Only fetches documents whose `lastModifiedAt` is after the
  /// locally persisted `_lastSyncPrefix + tableName` timestamp,
  /// dramatically reducing read costs on large collections.
  Future<void> _pullRemoteChanges(String uid) async {
    log('Starting incremental pull of remote changes...');
    final prefs = await SharedPreferences.getInstance();

    for (final tableName in tablesToSync) {
      try {
        log('Pulling $tableName from cloud...');

        // Incremental: only fetch docs modified after last sync
        final lastSyncMs = prefs.getInt('$_lastSyncPrefix$tableName');
        DateTime? since;
        if (lastSyncMs != null) {
          since = DateTime.fromMillisecondsSinceEpoch(lastSyncMs);
          log('Incremental pull for $tableName since '
              '${since.toIso8601String()}');
        } else {
          log('Full pull for $tableName (no previous sync)');
        }

        final records = await _cloudClient.pullRecords(
          userId: uid,
          collection: tableName,
          since: since,
        );

        if (records.isEmpty) {
          log('No new remote data for $tableName');
          continue;
        }

        log('Found ${records.length} changed records for $tableName');

        DateTime? latestTimestamp;

        for (final record in records) {
          try {
            final recordId = int.tryParse(record.id);

            if (recordId == null) {
              log('Invalid record ID: ${record.id}');
              continue;
            }

            // Track the latest timestamp for bookmark update
            if (latestTimestamp == null ||
                record.lastModifiedAt.isAfter(latestTimestamp)) {
              latestTimestamp = record.lastModifiedAt;
            }

            final localModifiedAt = await _getLocalModifiedAt(
              tableName,
              recordId,
            );

            if (localModifiedAt == null ||
                record.lastModifiedAt.isAfter(localModifiedAt)) {
              await _upsertLocalRecord(tableName, recordId, record.data);
              log('Pulled $tableName:$recordId (remote was newer)');
            } else {
              log('Skipped $tableName:$recordId (local is up to date)');
            }
          } catch (e) {
            log('Failed to process remote record ${record.id}: $e');
          }
        }

        // Persist the latest timestamp as bookmark for next sync
        if (latestTimestamp != null) {
          await prefs.setInt(
            '$_lastSyncPrefix$tableName',
            latestTimestamp.millisecondsSinceEpoch,
          );
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
  /// Does NOT add to sync queue (to avoid re-pushing back to cloud).
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
  /// Downloads all user data from cloud to local database.
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

    log('Starting initial sync for user: ${user.id}');

    try {
      await _pullRemoteChanges(user.id);

      final completedCount = await _database.syncDao.deleteCompletedOlderThan(
        DateTime.now().subtract(const Duration(days: 1)),
      );

      log('Initial sync completed. Cleaned up $completedCount old sync items.');
    } catch (e) {
      log('Initial sync failed: $e');
      rethrow;
    }
  }

  /// Deletes all user data from both Drift (local) and cloud.
  ///
  /// Used for GDPR right to erasure (Article 17).
  /// Steps:
  /// 1. Clear all local Drift tables
  /// 2. Delete all cloud data for the user
  /// 3. Delete the user document itself
  Future<void> deleteAllData() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated for data deletion');
    }

    log('Starting full data deletion for user: ${user.id}');

    // Step 1: Clear local Drift database
    await _database.deleteAllData();
    log('Local data cleared');

    // Step 2: Delete cloud data (if online)
    if (await _connectivity.isConnected()) {
      try {
        await _cloudClient.deleteAllUserData(
          userId: user.id,
          collections: [...tablesToSync, 'insights'],
        );
        log('Cloud user data deleted');
      } catch (e) {
        log('Error deleting cloud data: $e');
      }
    } else {
      log('Offline — Cloud deletion will be handled on next connection');
    }

    log('Full data deletion completed');
  }

  /// Checks if sync is currently in progress.
  bool get isSyncing => _isSyncing;

  /// Starts automatic sync on connectivity changes.
  /// Listens to connectivity stream and triggers sync when online.
  /// Safe to call multiple times — cancels any existing subscription first.
  void startAutoSync() {
    _autoSyncSubscription?.cancel();
    _autoSyncSubscription = _connectivity.connectivityStream.listen(
      (isConnected) {
        if (isConnected && !_isSyncing) {
          sync().catchError((error) {
            log('Auto-sync failed: $error');
          });
        }
      },
    );
  }

  /// Stops automatic sync and releases stream subscription.
  Future<void> stopAutoSync() async {
    await _autoSyncSubscription?.cancel();
    _autoSyncSubscription = null;
  }
}
