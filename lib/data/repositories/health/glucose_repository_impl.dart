import 'package:vitalsync/core/enums/glucose_source.dart';
import 'package:vitalsync/core/enums/sync_enums.dart';
import 'package:vitalsync/data/local/daos/health/glucose_dao.dart';
import 'package:vitalsync/data/local/database.dart';
import 'package:vitalsync/data/models/health/glucose_reading_model.dart';
import 'package:vitalsync/domain/entities/health/glucose_reading.dart';
import 'package:vitalsync/domain/repositories/health/glucose_repository.dart';

/// Only **manual** readings are pushed to the cloud.
///
/// A CGM feeds Apple Health roughly every five minutes — about 288 readings a
/// day — and a new device re-imports all of them from the health store anyway.
/// Backing them up to DynamoDB would multiply write cost for data that is
/// already recoverable. A hand-entered reading has no other source, so it is
/// the one kind worth paying to keep.
class GlucoseRepositoryImpl implements GlucoseRepository {
  GlucoseRepositoryImpl(this._dao, this._database);
  final GlucoseDao _dao;
  final AppDatabase _database;

  /// Cloud collection name. Must match the entry in
  /// `SyncService.tablesToSync` and the Lambda's `COLLECTION_PREFIX`.
  static const _collection = 'glucose_readings';

  @override
  Future<List<GlucoseReading>> getAll() async {
    final results = await _dao.getAll();
    return results.map(GlucoseReadingModel.fromDrift).toList();
  }

  @override
  Future<List<GlucoseReading>> getByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final results = await _dao.getByDateRange(start, end);
    return results.map(GlucoseReadingModel.fromDrift).toList();
  }

  @override
  Future<GlucoseReading?> getById(int id) async {
    final result = await _dao.getById(id);
    return result == null ? null : GlucoseReadingModel.fromDrift(result);
  }

  @override
  Future<int> insert(GlucoseReading reading) async {
    final model = GlucoseReadingModel.fromEntity(reading);
    final id = await _dao.insert(model.toCompanion());
    await _enqueueIfManual(id, SyncOperation.insert, model);
    return id;
  }

  @override
  Future<void> update(GlucoseReading reading) async {
    final model = GlucoseReadingModel.fromEntity(reading);
    final data = GlucoseReadingData(
      id: model.id,
      valueMgDl: model.valueMgDl,
      measuredAt: model.measuredAt,
      source: model.source,
      externalId: model.externalId,
      mealContext: model.mealContext,
      notes: model.notes,
      syncStatus: model.syncStatus,
      lastModifiedAt: model.lastModifiedAt,
      createdAt: model.createdAt,
    );
    await _dao.updateReading(data);
    await _enqueueIfManual(model.id, SyncOperation.update, model);
  }

  @override
  Future<void> delete(int id) async {
    // Read the row before deleting it: after the delete there is no way to
    // tell whether it was a manual entry, and queuing a delete for a reading
    // that was never pushed would ask the server to remove a record that does
    // not exist there.
    final existing = await _dao.getById(id);
    await _dao.deleteReading(id);
    if (existing?.source == GlucoseSource.manual) {
      await _database.addToSyncQueue(
        _collection,
        id,
        SyncOperation.delete,
        const {},
      );
    }
  }

  /// Queues a push only for hand-entered readings — see the class doc.
  Future<void> _enqueueIfManual(
    int id,
    SyncOperation operation,
    GlucoseReadingModel model,
  ) async {
    if (model.source != GlucoseSource.manual) return;
    await _database.addToSyncQueue(_collection, id, operation, model.toJson());
  }

  @override
  Future<bool> existsByExternalId(String externalId) {
    return _dao.existsByExternalId(externalId);
  }

  @override
  Stream<List<GlucoseReading>> watchRecent({int limit = 20}) {
    return _dao
        .watchRecent(limit: limit)
        .map((list) => list.map(GlucoseReadingModel.fromDrift).toList());
  }
}
