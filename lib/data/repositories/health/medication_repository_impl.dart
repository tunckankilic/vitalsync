import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:vitalsync/data/local/daos/health/medication_dao.dart';
import 'package:vitalsync/data/local/database.dart';
import 'package:vitalsync/data/models/health/medication_model.dart';
import 'package:vitalsync/domain/entities/health/medication.dart';
import 'package:vitalsync/domain/repositories/health/medication_repository.dart';

class MedicationRepositoryImpl implements MedicationRepository {
  MedicationRepositoryImpl(this._dao);
  final MedicationDao _dao;

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
  Future<int> insert(Medication medication) {
    return _dao.insert(MedicationModel.fromEntity(medication).toCompanion());
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
  }

  @override
  Future<void> delete(int id) {
    return _dao.deleteMedication(id);
  }

  @override
  Future<void> toggleActive(int id) async {
    final current = await _dao.getById(id);
    if (current != null) {
      await _dao.toggleActive(id, !current.isActive);
    }
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
