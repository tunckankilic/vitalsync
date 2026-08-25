import 'package:vitalsync/data/local/daos/health/glucose_dao.dart';
import 'package:vitalsync/data/local/database.dart';
import 'package:vitalsync/data/models/health/glucose_reading_model.dart';
import 'package:vitalsync/domain/entities/health/glucose_reading.dart';
import 'package:vitalsync/domain/repositories/health/glucose_repository.dart';

class GlucoseRepositoryImpl implements GlucoseRepository {
  GlucoseRepositoryImpl(this._dao);
  final GlucoseDao _dao;

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
  Future<int> insert(GlucoseReading reading) {
    return _dao.insert(GlucoseReadingModel.fromEntity(reading).toCompanion());
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
  }

  @override
  Future<void> delete(int id) {
    return _dao.deleteReading(id);
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
