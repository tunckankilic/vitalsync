import 'package:drift/drift.dart';
import 'package:vitalsync/core/enums/medication_log_status.dart';
import 'package:vitalsync/core/enums/sync_status.dart';
import 'package:vitalsync/data/local/daos/health/medication_dao.dart';
import 'package:vitalsync/data/local/database.dart';
import 'package:vitalsync/data/models/health/medication_log_model.dart';
import 'package:vitalsync/domain/entities/health/medication_log.dart';
import 'package:vitalsync/domain/repositories/health/medication_log_repository.dart';

class MedicationLogRepositoryImpl implements MedicationLogRepository {
  MedicationLogRepositoryImpl(this._dao);
  final MedicationLogDao _dao;

  @override
  Future<List<MedicationLog>> getByMedicationId(int medicationId) async {
    final results = await _dao.getByMedicationId(medicationId);
    return results.map(MedicationLogModel.fromDrift).toList();
  }

  @override
  Future<List<MedicationLog>> getByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final results = await _dao.getByDateRange(start, end);
    return results.map(MedicationLogModel.fromDrift).toList();
  }

  @override
  Future<List<MedicationLog>> getTodayLogs() async {
    final results = await _dao.getTodayLogs();
    return results.map(MedicationLogModel.fromDrift).toList();
  }

  @override
  Future<void> logMedication(int medicationId, MedicationLogStatus status) {
    // Basic implementation: Log for current time.
    // Ideally this should link to a scheduled slot, but for now we create a log.
    final now = DateTime.now();
    final companion = MedicationLogsCompanion(
      medicationId: Value(medicationId),
      scheduledTime: Value(now), // logging as ad-hoc or "now" match
      takenTime: Value(status == MedicationLogStatus.taken ? now : null),
      status: Value(status),
      syncStatus: const Value(SyncStatus.pending), // needs sync
      lastModifiedAt: Value(now),
      createdAt: Value(now),
    );
    return _dao.insert(companion);
  }

  @override
  Future<double> getComplianceRate(int medicationId, {int days = 7}) async {
    final logs = await _dao.getLogsForCompliance(medicationId, days);
    if (logs.isEmpty) return 0.0;

    final takenCount = logs
        .where((l) => l.status == MedicationLogStatus.taken)
        .length;
    return takenCount / logs.length;
  }

  @override
  Future<double> getOverallComplianceRate({int days = 7}) async {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days));
    final logs = await _dao.getByDateRange(start, now);

    if (logs.isEmpty) return 0.0;

    final takenCount = logs
        .where((l) => l.status == MedicationLogStatus.taken)
        .length;
    return takenCount / logs.length;
  }

  @override
  Future<Map<int, double>> getWeekdayComplianceMap({int days = 30}) async {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days));
    final logs = await _dao.getByDateRange(start, now);

    final map = <int, List<MedicationLogData>>{}; // Weekday -> Logs
    for (var log in logs) {
      final weekday = log.scheduledTime.weekday;
      map.putIfAbsent(weekday, () => []).add(log);
    }

    final result = <int, double>{};
    for (var i = 1; i <= 7; i++) {
      final dayLogs = map[i] ?? [];
      if (dayLogs.isEmpty) {
        result[i] = 0.0;
      } else {
        final taken = dayLogs
            .where((l) => l.status == MedicationLogStatus.taken)
            .length;
        result[i] = taken / dayLogs.length;
      }
    }
    return result;
  }

  @override
  Stream<List<MedicationLog>> watchTodayLogs() {
    return _dao.watchTodayLogs().map(
      (list) => list.map(MedicationLogModel.fromDrift).toList(),
    );
  }
}
