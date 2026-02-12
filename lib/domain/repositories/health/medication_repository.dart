/// VitalSync — Health Abstract Repositories.
///
/// Defines interfaces for MedicationRepository, MedicationLogRepository, and SymptomRepository.
library;

// Domain entities will be defined in Prompt 2.2
// For now, using placeholders

/// Abstract repository for medication data operations.
///
/// Provides CRUD operations and queries for medications.
/// Full method signatures from Prompt 2.3.
abstract class MedicationRepository {
  // TODO: Implement in Prompt 2.3 with full method signatures
  // Example methods:
  // Future<List<Medication>> getAll();
  // Future<Medication?> getById(int id);
  // Future<List<Medication>> getActive();
  // Future<int> insert(Medication medication);
  // Future<void> update(Medication medication);
  // Future<void> delete(int id);
  // Future<void> toggleActive(int id);
  // Stream<List<Medication>> watchAll();
  // Stream<List<Medication>> watchActive();
}

/// Abstract repository for medication log data operations.
///
/// Tracks medication adherence and compliance.
/// Full method signatures from Prompt 2.3.
abstract class MedicationLogRepository {
  // TODO: Implement in Prompt 2.3 with full method signatures
  // Example methods:
  // Future<List<MedicationLog>> getByMedicationId(int medicationId);
  // Future<List<MedicationLog>> getByDateRange(DateTime start, DateTime end);
  // Future<List<MedicationLog>> getTodayLogs();
  // Future<void> logMedication(int medicationId, MedicationLogStatus status);
  // Future<double> getComplianceRate(int medicationId, {int days = 7});
  // Future<double> getOverallComplianceRate({int days = 7});
  // Stream<List<MedicationLog>> watchTodayLogs();
}

/// Abstract repository for symptom data operations.
///
/// Tracks user-reported symptoms and severity.
/// Full method signatures from Prompt 2.3.
abstract class SymptomRepository {
  // TODO: Implement in Prompt 2.3 with full method signatures
  // Example methods:
  // Future<List<Symptom>> getAll();
  // Future<List<Symptom>> getByDateRange(DateTime start, DateTime end);
  // Future<int> insert(Symptom symptom);
  // Future<void> update(Symptom symptom);
  // Future<void> delete(int id);
  // Future<Map<String, int>> getSymptomFrequency({int days = 30});
  // Stream<List<Symptom>> watchRecent({int limit = 20});
}
