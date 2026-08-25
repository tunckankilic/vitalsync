import 'package:vitalsync/core/enums/health_sample_type.dart';
import 'package:vitalsync/data/local/daos/health/health_sample_dao.dart';
import 'package:vitalsync/data/local/database.dart';
import 'package:vitalsync/data/models/health/health_sample_model.dart';
import 'package:vitalsync/domain/entities/health/health_sample.dart';
import 'package:vitalsync/domain/repositories/health/health_sample_repository.dart';

class HealthSampleRepositoryImpl implements HealthSampleRepository {
  HealthSampleRepositoryImpl(this._dao);
  final HealthSampleDao _dao;

  @override
  Future<List<HealthSample>> getAll() async {
    final results = await _dao.getAll();
    return results.map(HealthSampleModel.fromDrift).toList();
  }

  @override
  Future<List<HealthSample>> getByDateRange(DateTime start, DateTime end) async {
    final results = await _dao.getByDateRange(start, end);
    return results.map(HealthSampleModel.fromDrift).toList();
  }

  @override
  Future<List<HealthSample>> getByTypeAndRange(
    HealthSampleType type,
    DateTime start,
    DateTime end,
  ) async {
    final results = await _dao.getByTypeAndRange(type, start, end);
    return results.map(HealthSampleModel.fromDrift).toList();
  }

  @override
  Future<HealthSample?> getById(int id) async {
    final result = await _dao.getById(id);
    return result == null ? null : HealthSampleModel.fromDrift(result);
  }

  @override
  Future<int> insert(HealthSample sample) {
    return _dao.insert(HealthSampleModel.fromEntity(sample).toCompanion());
  }

  @override
  Future<void> update(HealthSample sample) async {
    final model = HealthSampleModel.fromEntity(sample);
    final data = HealthSampleData(
      id: model.id,
      type: model.type,
      startAt: model.startAt,
      endAt: model.endAt,
      value: model.value,
      unit: model.unit,
      source: model.source,
      externalId: model.externalId,
      metadata: model.metadata,
      lastModifiedAt: model.lastModifiedAt,
      createdAt: model.createdAt,
    );
    await _dao.updateSample(data);
  }

  @override
  Future<void> delete(int id) {
    return _dao.deleteSample(id);
  }

  @override
  Future<bool> existsByExternalId(String externalId) {
    return _dao.existsByExternalId(externalId);
  }

  @override
  Stream<List<HealthSample>> watchRecent({int limit = 20}) {
    return _dao
        .watchRecent(limit: limit)
        .map((list) => list.map(HealthSampleModel.fromDrift).toList());
  }
}
