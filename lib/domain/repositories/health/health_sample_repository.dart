import 'package:vitalsync/core/enums/health_sample_type.dart';
import 'package:vitalsync/domain/entities/health/health_sample.dart';

abstract class HealthSampleRepository {
  Future<List<HealthSample>> getAll();
  Future<List<HealthSample>> getByDateRange(DateTime start, DateTime end);
  Future<List<HealthSample>> getByTypeAndRange(
    HealthSampleType type,
    DateTime start,
    DateTime end,
  );
  Future<HealthSample?> getById(int id);
  Future<int> insert(HealthSample sample);
  Future<void> update(HealthSample sample);
  Future<void> delete(int id);
  Future<bool> existsByExternalId(String externalId);
  Stream<List<HealthSample>> watchRecent({int limit = 20});
}
