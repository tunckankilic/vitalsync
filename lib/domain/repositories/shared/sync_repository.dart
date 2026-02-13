import 'package:vitalsync/core/enums/sync_enums.dart';

class SyncQueueItem {
  SyncQueueItem({
    required this.id,
    required this.tableName,
    required this.recordId,
    required this.operation,
    required this.payload,
    required this.status,
    required this.retryCount,
    required this.createdAt,
    this.lastAttemptAt,
  });
  final int id;
  final String tableName;
  final int recordId;
  final SyncOperation operation;
  final Map<String, dynamic> payload;
  final SyncQueueStatus status;
  final int retryCount;
  final DateTime createdAt;
  final DateTime? lastAttemptAt;
}

abstract class SyncRepository {
  Future<List<SyncQueueItem>> getPendingItems();
  Future<void> addToQueue(
    String tableName,
    int recordId,
    SyncOperation operation,
    Map<String, dynamic> payload,
  );
  Future<void> markCompleted(int id);
  Future<void> markFailed(int id);
  Future<void> processQueue();
  Future<void> pullFromFirestore();
}
