import 'dart:convert';
import 'package:vitalsync/core/enums/sync_enums.dart';
import 'package:vitalsync/data/local/daos/health/medication_dao.dart';
import 'package:vitalsync/data/local/database.dart';
import 'package:vitalsync/data/models/health/symptom_model.dart';
import 'package:vitalsync/domain/entities/health/symptom.dart';
import 'package:vitalsync/domain/repositories/health/symptom_repository.dart';

class SymptomRepositoryImpl implements SymptomRepository {
  SymptomRepositoryImpl(this._dao, this._database);
  final SymptomDao _dao;
  final AppDatabase _database;

  /// Cloud collection name. Must match the entry in
  /// `SyncService.tablesToSync` and the Lambda's `COLLECTION_PREFIX`.
  static const _collection = 'symptoms';

  @override
  Future<List<Symptom>> getAll() async {
    final results = await _dao.getAll();
    return results.map(SymptomModel.fromDrift).toList();
  }

  @override
  Future<List<Symptom>> getByDateRange(DateTime start, DateTime end) async {
    final results = await _dao.getByDateRange(start, end);
    return results.map(SymptomModel.fromDrift).toList();
  }

  @override
  Future<int> insert(Symptom symptom) async {
    final model = SymptomModel.fromEntity(symptom);
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
  Future<void> update(Symptom symptom) async {
    final model = SymptomModel.fromEntity(symptom);
    final data = SymptomData(
      id: model.id,
      name: model.name,
      severity: model.severity,
      date: model.date,
      notes: model.notes,
      tags: jsonEncode(
        model.tags,
      ), // Converted to JSON string as Drift expects String
      syncStatus: model.syncStatus,
      lastModifiedAt: model.lastModifiedAt,
      createdAt: model.createdAt,
    );
    await _dao.updateSymptom(data);
    await _database.addToSyncQueue(
      _collection,
      model.id,
      SyncOperation.update,
      model.toJson(),
    );
  }

  @override
  Future<void> delete(int id) async {
    await _dao.deleteSymptom(id);
    await _database.addToSyncQueue(
      _collection,
      id,
      SyncOperation.delete,
      const {},
    );
  }

  @override
  Future<Map<String, int>> getSymptomFrequency({int days = 30}) async {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days));
    final symptoms = await _dao.getByDateRange(start, now);

    final frequencyMap = <String, int>{};
    for (final symptom in symptoms) {
      frequencyMap[symptom.name] = (frequencyMap[symptom.name] ?? 0) + 1;
    }
    return frequencyMap;
  }

  @override
  Future<Map<String, double>> getAverageSeverityByName({int days = 30}) async {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days));
    final symptoms = await _dao.getByDateRange(start, now);

    final sumMap = <String, int>{};
    final countMap = <String, int>{};

    for (final symptom in symptoms) {
      sumMap[symptom.name] = (sumMap[symptom.name] ?? 0) + symptom.severity;
      countMap[symptom.name] = (countMap[symptom.name] ?? 0) + 1;
    }

    final averageMap = <String, double>{};
    sumMap.forEach((key, sum) {
      final count = countMap[key] ?? 1;
      averageMap[key] = sum / count;
    });

    return averageMap;
  }

  @override
  Stream<List<Symptom>> watchRecent({int limit = 20}) {
    return _dao
        .watchRecent(limit: limit)
        .map((list) => list.map(SymptomModel.fromDrift).toList());
  }
}
