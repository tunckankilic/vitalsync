import 'package:vitalsync/domain/entities/fitness/personal_record.dart';

abstract class PersonalRecordRepository {
  Future<List<PersonalRecord>> getAll();
  Future<PersonalRecord?> getForExercise(int exerciseId);
  Future<List<PersonalRecord>> getRecent({int limit = 10});
  Future<void> checkAndUpdatePR(int exerciseId, double weight, int reps);
  Stream<List<PersonalRecord>> watchRecent();
}
