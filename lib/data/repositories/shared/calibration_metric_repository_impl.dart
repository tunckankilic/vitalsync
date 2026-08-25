import 'dart:convert';
import 'package:vitalsync/data/local/daos/shared/calibration_metric_dao.dart';
import 'package:vitalsync/data/local/database.dart';
import 'package:vitalsync/data/models/shared/calibration_metric_model.dart';
import 'package:vitalsync/domain/entities/shared/calibration_metric.dart';
import 'package:vitalsync/domain/repositories/shared/calibration_metric_repository.dart';

/// **Counts only, no interpretation.** Every method below moves tallies
/// between the DAO and the domain layer. Nothing here derives a rating,
/// a score or a statement about what the counters mean.
class CalibrationMetricRepositoryImpl implements CalibrationMetricRepository {
  CalibrationMetricRepositoryImpl(this._dao);
  final CalibrationMetricDao _dao;

  @override
  Future<List<CalibrationMetric>> getAll() async {
    final results = await _dao.getAll();
    return results.map(CalibrationMetricModel.fromDrift).toList();
  }

  @override
  Future<List<CalibrationMetric>> getByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final results = await _dao.getByDateRange(start, end);
    return results.map(CalibrationMetricModel.fromDrift).toList();
  }

  @override
  Future<CalibrationMetric?> getById(int id) async {
    final result = await _dao.getById(id);
    return result == null ? null : CalibrationMetricModel.fromDrift(result);
  }

  @override
  Future<CalibrationMetric?> getByWeekStart(DateTime weekStart) async {
    final result = await _dao.getByWeekStart(weekStart);
    return result == null ? null : CalibrationMetricModel.fromDrift(result);
  }

  @override
  Future<int> insert(CalibrationMetric metric) {
    return _dao.insert(CalibrationMetricModel.fromEntity(metric).toCompanion());
  }

  @override
  Future<void> update(CalibrationMetric metric) async {
    final model = CalibrationMetricModel.fromEntity(metric);
    final data = CalibrationMetricData(
      id: model.id,
      weekStart: model.weekStart,
      mealsLogged: model.mealsLogged,
      glucoseReadings: model.glucoseReadings,
      manualReadings: model.manualReadings,
      coveredMeals: model.coveredMeals,
      uncoveredReasons: jsonEncode(
        model.uncoveredReasons,
      ), // Converted to JSON string as Drift expects String
      appVersion: model.appVersion,
      syncStatus: model.syncStatus,
      lastModifiedAt: model.lastModifiedAt,
      createdAt: model.createdAt,
    );
    await _dao.updateMetric(data);
  }

  @override
  Future<void> delete(int id) {
    return _dao.deleteMetric(id);
  }

  @override
  Stream<List<CalibrationMetric>> watchRecent({int limit = 20}) {
    return _dao
        .watchRecent(limit: limit)
        .map((list) => list.map(CalibrationMetricModel.fromDrift).toList());
  }
}
