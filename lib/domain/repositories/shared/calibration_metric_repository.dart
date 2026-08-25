import 'package:vitalsync/domain/entities/shared/calibration_metric.dart';

/// Weekly calibration counters.
///
/// **Counts only, no interpretation.** This repository stores and returns
/// tallies; it never derives a rating, a score or a statement about them.
abstract class CalibrationMetricRepository {
  Future<List<CalibrationMetric>> getAll();
  Future<List<CalibrationMetric>> getByDateRange(DateTime start, DateTime end);
  Future<CalibrationMetric?> getById(int id);
  Future<CalibrationMetric?> getByWeekStart(DateTime weekStart);
  Future<int> insert(CalibrationMetric metric);
  Future<void> update(CalibrationMetric metric);
  Future<void> delete(int id);
  Stream<List<CalibrationMetric>> watchRecent({int limit = 20});
}
