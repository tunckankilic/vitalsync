import 'package:vitalsync/domain/entities/fitness/workout_session.dart';
import 'package:vitalsync/domain/entities/fitness/workout_set.dart';

abstract class WorkoutSessionRepository {
  Future<List<WorkoutSession>> getAll();
  Future<List<WorkoutSession>> getByDateRange(DateTime start, DateTime end);
  Future<WorkoutSession?> getById(int id);
  Future<WorkoutSession?> getLastSession();
  Future<int> startSession(WorkoutSession session);
  Future<void> endSession(int id, {String? notes, int? rating});
  Future<void> addSet(WorkoutSet set);
  Future<void> updateSet(WorkoutSet set);
  Future<void> deleteSet(int id);
  Future<List<WorkoutSet>> getSessionSets(int sessionId);
  Future<double> getTotalVolume({int? days});
  Future<int> getWorkoutCount({int? days});
  Future<List<DateTime>> getWorkoutDates({int days = 30});
  Stream<WorkoutSession?> watchActiveSession();
}
