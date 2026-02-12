import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:vitalsync/data/local/daos/health/medication_dao.dart';
import 'package:vitalsync/data/local/database.dart';
import 'package:vitalsync/data/models/health/symptom_model.dart';
import 'package:vitalsync/domain/entities/health/symptom.dart';
import 'package:vitalsync/domain/repositories/health/symptom_repository.dart';

class SymptomRepositoryImpl implements SymptomRepository {
  SymptomRepositoryImpl(this._dao);
  final SymptomDao _dao;

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
  Future<int> insert(Symptom symptom) {
    return _dao.insert(SymptomModel.fromEntity(symptom).toCompanion());
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
  }

  @override
  Future<void> delete(int id) {
    return _dao.deleteSymptom(id);
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
