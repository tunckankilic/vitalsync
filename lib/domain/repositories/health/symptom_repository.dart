import 'package:vitalsync/domain/entities/health/symptom.dart';

abstract class SymptomRepository {
  Future<List<Symptom>> getAll();
  Future<List<Symptom>> getByDateRange(DateTime start, DateTime end);
  Future<int> insert(Symptom symptom);
  Future<void> update(Symptom symptom);
  Future<void> delete(int id);
  Future<Map<String, int>> getSymptomFrequency({int days = 30});
  Future<Map<String, double>> getAverageSeverityByName({int days = 30});
  Stream<List<Symptom>> watchRecent({int limit = 20});
}
