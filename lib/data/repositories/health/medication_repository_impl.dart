/// VitalSync — Health Repository Implementations.
///
/// Concrete implementations for Medication, MedicationLog, and Symptom repositories.
library;

import '../../../data/local/database.dart';
import '../../../domain/repositories/health/medication_repository.dart';

/// Concrete implementation of MedicationRepository.
///
/// Uses Drift AppDatabase for data persistence.
/// Full implementation in Prompt 2.3.
class MedicationRepositoryImpl implements MedicationRepository {
  MedicationRepositoryImpl({required AppDatabase database})
    : _database = database;
  final AppDatabase _database;

  // TODO: Implement all methods in Prompt 2.3
  // Methods will throw UnimplementedError until then
}

/// Concrete implementation of MedicationLogRepository.
///
/// Uses Drift AppDatabase for data persistence.
/// Full implementation in Prompt 2.3.
class MedicationLogRepositoryImpl implements MedicationLogRepository {
  MedicationLogRepositoryImpl({required AppDatabase database})
    : _database = database;
  final AppDatabase _database;

  // TODO: Implement all methods in Prompt 2.3
  // Methods will throw UnimplementedError until then
}

/// Concrete implementation of SymptomRepository.
///
/// Uses Drift AppDatabase for data persistence.
/// Full implementation in Prompt 2.3.
class SymptomRepositoryImpl implements SymptomRepository {
  SymptomRepositoryImpl({required AppDatabase database}) : _database = database;
  final AppDatabase _database;

  // TODO: Implement all methods in Prompt 2.3
  // Methods will throw UnimplementedError until then
}
