import 'package:vitalsync/domain/entities/health/glucose_reading.dart';

abstract class GlucoseRepository {
  Future<List<GlucoseReading>> getAll();
  Future<List<GlucoseReading>> getByDateRange(DateTime start, DateTime end);
  Future<GlucoseReading?> getById(int id);
  Future<int> insert(GlucoseReading reading);
  Future<void> update(GlucoseReading reading);
  Future<void> delete(int id);
  Future<bool> existsByExternalId(String externalId);
  Stream<List<GlucoseReading>> watchRecent({int limit = 20});
}
