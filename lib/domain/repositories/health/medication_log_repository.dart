import 'package:vitalsync/core/enums/medication_log_status.dart';
import 'package:vitalsync/domain/entities/health/medication_log.dart';

abstract class MedicationLogRepository {
  Future<List<MedicationLog>> getByMedicationId(int medicationId);
  Future<List<MedicationLog>> getByDateRange(DateTime start, DateTime end);
  Future<List<MedicationLog>> getTodayLogs();
  Future<void> logMedication(int medicationId, MedicationLogStatus status);
  Future<double> getComplianceRate(int medicationId, {int days = 7});
  Future<double> getOverallComplianceRate({int days = 7});
  Future<Map<int, double>> getWeekdayComplianceMap({int days = 30});
  Stream<List<MedicationLog>> watchTodayLogs();
}
