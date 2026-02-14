/// VitalSync — Health Module DAOs (Medication, Medication Log, Symptom).
library;

import 'package:drift/drift.dart';
import 'package:vitalsync/core/enums/medication_frequency.dart';
import 'package:vitalsync/core/enums/medication_log_status.dart';
import 'package:vitalsync/core/enums/sync_status.dart';
import 'package:vitalsync/data/local/database.dart';

import '../../tables/health/medication_logs_table.dart';
import '../../tables/health/medications_table.dart';
import '../../tables/health/symptoms_table.dart';

part 'medication_dao.g.dart';

/// DAO for medication operations.
@DriftAccessor(tables: [Medications, MedicationLogs])
class MedicationDao extends DatabaseAccessor<AppDatabase>
    with _$MedicationDaoMixin {
  MedicationDao(super.db);

  /// Get all medications.
  Future<List<MedicationData>> getAll() {
    return select(medications).get();
  }

  /// Get a medication by ID.
  Future<MedicationData?> getById(int id) {
    return (select(
      medications,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Get all active medications.
  Future<List<MedicationData>> getActive() {
    return (select(
      medications,
    )..where((tbl) => tbl.isActive.equals(true))).get();
  }

  /// Insert a new medication.
  Future<int> insert(MedicationsCompanion medication) {
    return into(medications).insert(medication);
  }

  /// Update an existing medication.
  Future<bool> updateMedication(MedicationData medication) {
    return update(medications).replace(medication);
  }

  /// Delete a medication by ID.
  Future<int> deleteMedication(int id) {
    return (delete(medications)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Toggle active status of a medication.
  Future<bool> toggleActive(int id, bool newStatus) async {
    final rowsAffected =
        await (update(medications)..where((tbl) => tbl.id.equals(id))).write(
          MedicationsCompanion(
            isActive: Value(newStatus),
            updatedAt: Value(DateTime.now()),
          ),
        );
    return rowsAffected > 0;
  }

  /// Watch all medications.
  Stream<List<MedicationData>> watchAll() {
    return select(medications).watch();
  }

  /// Watch active medications.
  Stream<List<MedicationData>> watchActive() {
    return (select(
      medications,
    )..where((tbl) => tbl.isActive.equals(true))).watch();
  }

  /// Inserts or updates a medication from Firestore remote data.
  /// Sets [syncStatus] to [SyncStatus.synced] to prevent re-pushing.
  /// Does NOT trigger sync queue insertion.
  Future<void> upsertFromRemote(int id, Map<String, dynamic> data) async {
    await into(medications).insertOnConflictUpdate(
      MedicationsCompanion(
        id: Value(id),
        name: Value(data['name'] as String),
        dosage: Value(data['dosage'] as String? ?? ''),
        frequency: Value(
          MedicationFrequency.values.firstWhere(
            (e) => e.name == data['frequency'],
            orElse: () => MedicationFrequency.daily,
          ),
        ),
        times: Value(data['times'] as String? ?? '[]'),
        startDate: Value(DateTime.parse(data['startDate'] as String)),
        endDate: Value(
          data['endDate'] != null
              ? DateTime.parse(data['endDate'] as String)
              : null,
        ),
        notes: Value(data['notes'] as String?),
        color: Value(data['color'] as int? ?? 0xFF4CAF50),
        isActive: Value(data['isActive'] as bool? ?? true),
        syncStatus: const Value(SyncStatus.synced),
        lastModifiedAt: Value(DateTime.parse(data['lastModifiedAt'] as String)),
        createdAt: Value(DateTime.parse(data['createdAt'] as String)),
        updatedAt: Value(DateTime.parse(data['updatedAt'] as String)),
      ),
    );
  }
}

/// DAO for medication log operations.
@DriftAccessor(tables: [MedicationLogs])
class MedicationLogDao extends DatabaseAccessor<AppDatabase>
    with _$MedicationLogDaoMixin {
  MedicationLogDao(super.db);

  /// Get logs for a specific medication.
  Future<List<MedicationLogData>> getByMedicationId(int medicationId) {
    return (select(medicationLogs)
          ..where((tbl) => tbl.medicationId.equals(medicationId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.scheduledTime)]))
        .get();
  }

  /// Get logs within a date range.
  Future<List<MedicationLogData>> getByDateRange(DateTime start, DateTime end) {
    return (select(medicationLogs)
          ..where(
            (tbl) =>
                tbl.scheduledTime.isBiggerOrEqualValue(start) &
                tbl.scheduledTime.isSmallerOrEqualValue(end),
          )
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.scheduledTime)]))
        .get();
  }

  /// Get today's medication logs.
  Future<List<MedicationLogData>> getTodayLogs() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return getByDateRange(startOfDay, endOfDay);
  }

  /// Insert a medication log.
  Future<int> insert(MedicationLogsCompanion log) {
    return into(medicationLogs).insert(log);
  }

  /// Update a medication log.
  Future<bool> updateLog(MedicationLogData log) {
    return update(medicationLogs).replace(log);
  }

  /// Delete a medication log.
  Future<int> deleteLog(int id) {
    return (delete(medicationLogs)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Watch today's medication logs.
  Stream<List<MedicationLogData>> watchTodayLogs() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (select(medicationLogs)
          ..where(
            (tbl) =>
                tbl.scheduledTime.isBiggerOrEqualValue(startOfDay) &
                tbl.scheduledTime.isSmallerOrEqualValue(endOfDay),
          )
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.scheduledTime)]))
        .watch();
  }

  /// Get logs for compliance calculation.
  Future<List<MedicationLogData>> getLogsForCompliance(
    int medicationId,
    int days,
  ) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return (select(medicationLogs)
          ..where(
            (tbl) =>
                tbl.medicationId.equals(medicationId) &
                tbl.scheduledTime.isBiggerOrEqualValue(cutoff),
          )
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.scheduledTime)]))
        .get();
  }

  /// Inserts or updates a medication log from Firestore remote data.
  Future<void> upsertFromRemote(int id, Map<String, dynamic> data) async {
    await into(medicationLogs).insertOnConflictUpdate(
      MedicationLogsCompanion(
        id: Value(id),
        medicationId: Value(data['medicationId'] as int),
        scheduledTime: Value(DateTime.parse(data['scheduledTime'] as String)),
        takenTime: Value(
          data['takenTime'] != null
              ? DateTime.parse(data['takenTime'] as String)
              : null,
        ),
        status: Value(
          MedicationLogStatus.values.firstWhere(
            (e) => e.name == data['status'],
            orElse: () => MedicationLogStatus.pending,
          ),
        ),
        notes: Value(data['notes'] as String?),
        syncStatus: const Value(SyncStatus.synced),
        lastModifiedAt: Value(DateTime.parse(data['lastModifiedAt'] as String)),
        createdAt: Value(DateTime.parse(data['createdAt'] as String)),
      ),
    );
  }

  /// Returns a single medication log by ID, or null if not found.
  Future<MedicationLogData?> getById(int id) async {
    return (select(
      medicationLogs,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }
}

/// DAO for symptom operations.
@DriftAccessor(tables: [Symptoms])
class SymptomDao extends DatabaseAccessor<AppDatabase> with _$SymptomDaoMixin {
  SymptomDao(super.db);

  /// Get all symptoms.
  Future<List<SymptomData>> getAll() {
    return (select(
      symptoms,
    )..orderBy([(tbl) => OrderingTerm.desc(tbl.date)])).get();
  }

  /// Get symptoms within a date range.
  Future<List<SymptomData>> getByDateRange(DateTime start, DateTime end) {
    return (select(symptoms)
          ..where(
            (tbl) =>
                tbl.date.isBiggerOrEqualValue(start) &
                tbl.date.isSmallerOrEqualValue(end),
          )
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.date)]))
        .get();
  }

  /// Get recent symptoms (limited).
  Future<List<SymptomData>> getRecent({int limit = 20}) {
    return (select(symptoms)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.date)])
          ..limit(limit))
        .get();
  }

  /// Insert a new symptom.
  Future<int> insert(SymptomsCompanion symptom) {
    return into(symptoms).insert(symptom);
  }

  /// Update an existing symptom.
  Future<bool> updateSymptom(SymptomData symptom) {
    return update(symptoms).replace(symptom);
  }

  /// Delete a symptom.
  Future<int> deleteSymptom(int id) {
    return (delete(symptoms)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Watch recent symptoms.
  Stream<List<SymptomData>> watchRecent({int limit = 20}) {
    return (select(symptoms)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.date)])
          ..limit(limit))
        .watch();
  }

  /// Inserts or updates a symptom record from Firestore remote data.
  Future<void> upsertFromRemote(int id, Map<String, dynamic> data) async {
    await into(symptoms).insertOnConflictUpdate(
      SymptomsCompanion(
        id: Value(id),
        name: Value(data['name'] as String),
        severity: Value(data['severity'] as int),
        date: Value(DateTime.parse(data['date'] as String)),
        notes: Value(data['notes'] as String?),
        tags: Value(data['tags'] as String? ?? '[]'),
        syncStatus: const Value(SyncStatus.synced),
        lastModifiedAt: Value(DateTime.parse(data['lastModifiedAt'] as String)),
        createdAt: Value(DateTime.parse(data['createdAt'] as String)),
      ),
    );
  }

  /// Returns a single symptom by ID, or null if not found.
  Future<SymptomData?> getById(int id) async {
    return (select(symptoms)..where((t) => t.id.equals(id))).getSingleOrNull();
  }
}
