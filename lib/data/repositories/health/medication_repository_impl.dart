import 'dart:convert';

import 'package:vitalsync/core/enums/sync_enums.dart';
import 'package:vitalsync/data/local/daos/health/medication_dao.dart';
import 'package:vitalsync/data/local/database.dart';
import 'package:vitalsync/data/models/health/medication_model.dart';
import 'package:vitalsync/domain/entities/health/medication.dart';
import 'package:vitalsync/domain/repositories/health/medication_repository.dart';

class MedicationRepositoryImpl implements MedicationRepository {
  MedicationRepositoryImpl(this._dao, this._database);
  final MedicationDao _dao;
  final AppDatabase _database;

  /// Cloud collection name. Must match the entry in
  /// `SyncService.tablesToSync` and the Lambda's `COLLECTION_PREFIX`.
  static const _collection = 'medications';

  @override
  Future<List<Medication>> getAll() async {
    final results = await _dao.getAll();
    return results.map(MedicationModel.fromDrift).toList();
  }

  @override
  Future<Medication?> getById(int id) async {
    final result = await _dao.getById(id);
    return result != null ? MedicationModel.fromDrift(result) : null;
  }

  @override
  Future<List<Medication>> getActive() async {
    final results = await _dao.getActive();
    return results.map(MedicationModel.fromDrift).toList();
  }

  @override
  Future<int> insert(Medication medication) async {
    final model = MedicationModel.fromEntity(medication);
    final id = await _dao.insert(model.toCompanion());
    await _database.addToSyncQueue(
      _collection,
      id,
      SyncOperation.insert,
      model.toJson(),
    );
    return id;
  }

  @override
  Future<void> update(Medication medication) async {
    final model = MedicationModel.fromEntity(medication);
    // Construct MedicationData manually from model as generated classes don't support converting from companion easily without context
    final data = MedicationData(
      id: model.id,
      name: model.name,
      dosage: model.dosage,
      frequency: model.frequency,
      times: jsonEncode(model.times),
      startDate: model.startDate,
      endDate: model.endDate,
      notes: model.notes,
      color: model.color,
      isActive: model.isActive,
      syncStatus: model.syncStatus,
      lastModifiedAt: model.lastModifiedAt,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
    await _dao.updateMedication(data);
    await _database.addToSyncQueue(
      _collection,
      model.id,
      SyncOperation.update,
      model.toJson(),
    );
  }

  @override
  Future<void> delete(int id) async {
    await _dao.deleteMedication(id);
    await _database.addToSyncQueue(
      _collection,
      id,
      SyncOperation.delete,
      const {},
    );
  }

  @override
  Future<void> toggleActive(int id) async {
    final current = await _dao.getById(id);
    if (current == null) return;

    await _dao.toggleActive(id, !current.isActive);

    // Re-read so the pushed payload carries the flipped flag and the
    // timestamp the DAO wrote, not the stale row above.
    final updated = await _dao.getById(id);
    if (updated == null) return;
    await _database.addToSyncQueue(
      _collection,
      id,
      SyncOperation.update,
      MedicationModel.fromDrift(updated).toJson(),
    );
  }

  @override
  Stream<List<Medication>> watchAll() {
    return _dao.watchAll().map(
      (list) => list.map(MedicationModel.fromDrift).toList(),
    );
  }

  @override
  Stream<List<Medication>> watchActive() {
    return _dao.watchActive().map(
      (list) => list.map(MedicationModel.fromDrift).toList(),
    );
  }
}
