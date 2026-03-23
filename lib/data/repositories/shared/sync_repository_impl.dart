import 'dart:convert';
import 'dart:developer' show log;

import 'package:vitalsync/core/enums/sync_enums.dart';
import 'package:vitalsync/core/sync/cloud_sync_client.dart';
import 'package:vitalsync/data/local/daos/shared/user_profile_dao.dart';
import 'package:vitalsync/data/local/database.dart';
import 'package:vitalsync/domain/repositories/shared/auth_repository.dart';
import 'package:vitalsync/domain/repositories/shared/sync_repository.dart';

class SyncRepositoryImpl implements SyncRepository {
  SyncRepositoryImpl(
    this._syncDao,
    this._cloudClient,
    this._database,
    this._auth,
  );
  final SyncDao _syncDao;
  final CloudSyncClient _cloudClient;
  final AppDatabase _database;
  final AuthRepository _auth;

  @override
  Future<List<SyncQueueItem>> getPendingItems() async {
    final results = await _syncDao.getPendingItems();
    return results
        .map(
          (e) => SyncQueueItem(
            id: e.id,
            tableName: e.targetTable,
            recordId: e.recordId,
            operation: SyncOperation.values.firstWhere(
              (op) => op.name == e.operation.name,
              orElse: () => SyncOperation.insert,
            ),
            payload: jsonDecode(e.payload),
            status: SyncQueueStatus.values.firstWhere(
              (s) => s.name == e.status.name,
              orElse: () => SyncQueueStatus.pending,
            ),
            retryCount: e.retryCount,
            createdAt: e.createdAt,
            lastAttemptAt: e.lastAttemptAt,
          ),
        )
        .toList();
  }

  @override
  Future<void> addToQueue(
    String tableName,
    int recordId,
    SyncOperation operation,
    Map<String, dynamic> payload,
  ) {
    return _syncDao.addToQueue(
      SyncQueueCompanion.insert(
        targetTable: tableName,
        recordId: recordId,
        operation: operation,
        payload: jsonEncode(payload),
      ),
    );
  }

  @override
  Future<void> markCompleted(int id) async {
    await _syncDao.markCompleted(id);
  }

  @override
  Future<void> markFailed(int id) async {
    final pending = await _syncDao.getPendingItems();
    final item = pending.firstWhere(
      (e) => e.id == id,
      orElse: () => throw Exception('Item not found'),
    );
    await _syncDao.markFailed(id, item.retryCount);
  }

  @override
  Future<void> processQueue() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated to process sync queue');
    }

    final items = await getPendingItems();
    for (final item in items) {
      try {
        await _pushToCloud(user.id, item);
        await markCompleted(item.id);
      } catch (e) {
        await markFailed(item.id);
      }
    }
  }

  Future<void> _pushToCloud(String userId, SyncQueueItem item) async {
    switch (item.operation) {
      case SyncOperation.insert:
      case SyncOperation.update:
        await _cloudClient.pushRecord(
          userId: userId,
          collection: item.tableName,
          recordId: item.recordId.toString(),
          data: item.payload,
        );
      case SyncOperation.delete:
        await _cloudClient.deleteRecord(
          userId: userId,
          collection: item.tableName,
          recordId: item.recordId.toString(),
        );
    }
  }

  @override
  Future<void> pullFromCloud() async {
    // Get current user
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated to pull from cloud');
    }

    final uid = user.id;
    log('Starting pullFromCloud for user: $uid');

    // All collections to sync
    final tablesToSync = [
      'medications',
      'medication_logs',
      'symptoms',
      'workout_sessions',
      'workout_sets',
      'personal_records',
      'user_stats',
    ];

    var totalPulled = 0;

    for (final tableName in tablesToSync) {
      try {
        log('Pulling $tableName from cloud...');

        final records = await _cloudClient.pullRecords(
          userId: uid,
          collection: tableName,
        );

        if (records.isEmpty) {
          log('No remote data for $tableName');
          continue;
        }

        log('Found ${records.length} remote records for $tableName');

        for (final record in records) {
          try {
            final recordId = int.tryParse(record.id);

            if (recordId == null) {
              log('Invalid record ID: ${record.id}, skipping');
              continue;
            }

            // Get local record's lastModifiedAt for comparison
            final localModifiedAt = await _getLocalModifiedAt(
              tableName,
              recordId,
            );

            // If local doesn't exist or remote is newer → upsert
            if (localModifiedAt == null ||
                record.lastModifiedAt.isAfter(localModifiedAt)) {
              await _upsertLocalRecord(tableName, recordId, record.data);
              totalPulled++;
              log('Pulled $tableName:$recordId (remote was newer)');
            } else {
              log('Skipped $tableName:$recordId (local is up to date)');
            }
          } catch (e) {
            log('Failed to process remote record ${record.id}: $e');
          }
        }
      } catch (e) {
        log('Failed to pull $tableName: $e');
      }
    }

    log('Finished pullFromCloud. Total records pulled: $totalPulled');
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
      case 'workout_sets':
        final record = await _database.workoutSessionDao.getSetById(recordId);
        return record?.completedAt;
      case 'personal_records':
        final record = await _database.personalRecordDao.getById(recordId);
        return record?.achievedAt;
      case 'user_stats':
        final record = await _database.userStatsDao.getById(recordId);
        return record?.date;
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
      case 'user_stats':
        await _database.userStatsDao.upsertFromRemote(recordId, data);
      default:
        log('Unknown table for upsert: $tableName');
    }
  }
}
