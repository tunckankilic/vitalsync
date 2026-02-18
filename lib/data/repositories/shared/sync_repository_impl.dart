import 'dart:convert';
import 'dart:developer' show log;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vitalsync/core/enums/sync_enums.dart';
import 'package:vitalsync/data/local/daos/shared/user_profile_dao.dart';
import 'package:vitalsync/data/local/database.dart';
import 'package:vitalsync/domain/repositories/shared/sync_repository.dart';

class SyncRepositoryImpl implements SyncRepository {
  SyncRepositoryImpl(
    this._syncDao,
    this._firestore,
    this._database,
    this._auth,
  );
  final SyncDao _syncDao;
  final FirebaseFirestore _firestore;
  final AppDatabase _database;
  final FirebaseAuth _auth;

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
    final items = await getPendingItems();
    for (final item in items) {
      try {
        await _pushToFirestore(item);
        await markCompleted(item.id);
      } catch (e) {
        await markFailed(item.id);
      }
    }
  }

  Future<void> _pushToFirestore(SyncQueueItem item) async {
    final collection = _firestore.collection(item.tableName);
    final docRef = collection.doc(item.recordId.toString());

    switch (item.operation) {
      case SyncOperation.insert:
      case SyncOperation.update:
        await docRef.set(item.payload, SetOptions(merge: true));
        break;
      case SyncOperation.delete:
        await docRef.delete();
        break;
    }
  }

  @override
  Future<void> pullFromFirestore() async {
    // Get current user
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated to pull from Firestore');
    }

    final uid = user.uid;
    log('Starting pullFromFirestore for user: $uid');

    // All collections to sync
    // Note: Only including tables with full DAO support (getById + upsertFromRemote)
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
        log('Pulling $tableName from Firestore...');

        final collectionRef = _firestore
            .collection('users')
            .doc(uid)
            .collection(tableName);

        // Fetch all documents in batches
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
              log('Invalid document ID: ${doc.id}, skipping');
              continue;
            }

            // Convert Firestore format to local format
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
              totalPulled++;
              log('Pulled $tableName:$recordId (remote was newer)');
            } else {
              log('Skipped $tableName:$recordId (local is up to date)');
            }
          } catch (e) {
            log('Failed to process remote document ${doc.id}: $e');
            // Continue with next document
          }
        }
      } catch (e) {
        log('Failed to pull $tableName: $e');
        // Continue with next table
      }
    }

    log('Finished pullFromFirestore. Total records pulled: $totalPulled');
  }

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
      case 'user_stats':
        await _database.userStatsDao.upsertFromRemote(recordId, data);
      default:
        log('Unknown table for upsert: $tableName');
    }
  }
}
