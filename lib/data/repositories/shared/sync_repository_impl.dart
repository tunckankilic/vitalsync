import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:vitalsync/core/enums/sync_enums.dart';
import 'package:vitalsync/data/local/daos/shared/user_profile_dao.dart';
import 'package:vitalsync/data/local/database.dart';
import 'package:vitalsync/domain/repositories/shared/sync_repository.dart';

class SyncRepositoryImpl implements SyncRepository {
  SyncRepositoryImpl(this._syncDao, this._firestore);
  final SyncDao _syncDao;
  final FirebaseFirestore _firestore;

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
    // TODO: implement pullFromFirestore
  }
}
