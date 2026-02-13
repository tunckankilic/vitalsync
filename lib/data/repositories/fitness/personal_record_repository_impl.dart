import 'package:drift/drift.dart';
import 'package:vitalsync/data/local/daos/fitness/workout_dao.dart';
import 'package:vitalsync/data/local/database.dart';
import 'package:vitalsync/data/models/fitness/personal_record_model.dart';
import 'package:vitalsync/domain/entities/fitness/personal_record.dart';
import 'package:vitalsync/domain/repositories/fitness/personal_record_repository.dart';

class PersonalRecordRepositoryImpl implements PersonalRecordRepository {
  PersonalRecordRepositoryImpl(this._dao);
  final PersonalRecordDao _dao;

  @override
  Future<List<PersonalRecord>> getAll() async {
    final results = await _dao.getAll();
    return results.map(PersonalRecordModel.fromDrift).toList();
  }

  @override
  Future<PersonalRecord?> getForExercise(int exerciseId) async {
    final result = await _dao.getForExercise(exerciseId);
    return result != null ? PersonalRecordModel.fromDrift(result) : null;
  }

  @override
  Future<List<PersonalRecord>> getRecent({int limit = 10}) async {
    final results = await _dao.getRecent(limit: limit);
    return results.map(PersonalRecordModel.fromDrift).toList();
  }

  @override
  Future<void> checkAndUpdatePR(int exerciseId, double weight, int reps) async {
    // Basic 1RM calculation (Brzycki Formula)
    // 1RM = Weight / (1.0278 - (0.0278 * Reps))
    final estimated1RM = weight / (1.0278 - (0.0278 * reps));

    final existing = await _dao.getForExercise(exerciseId);

    if (existing == null || estimated1RM > existing.estimated1RM) {
      final now = DateTime.now();
      final companion = PersonalRecordsCompanion(
        exerciseId: Value(exerciseId),
        weight: Value(weight),
        reps: Value(reps),
        estimated1RM: Value(estimated1RM),
        achievedAt: Value(now),
      );
      await _dao.insert(companion);
    }
  }

  @override
  Stream<List<PersonalRecord>> watchRecent() {
    return _dao.watchRecent().map(
      (list) => list.map(PersonalRecordModel.fromDrift).toList(),
    );
  }
}
