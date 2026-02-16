import 'package:vitalsync/data/local/daos/fitness/workout_dao.dart';
import 'package:vitalsync/data/local/database.dart';
import 'package:vitalsync/data/models/fitness/workout_session_model.dart';
import 'package:vitalsync/data/models/fitness/workout_set_model.dart';
import 'package:vitalsync/domain/entities/fitness/workout_session.dart';
import 'package:vitalsync/domain/entities/fitness/workout_set.dart';
import 'package:vitalsync/domain/repositories/fitness/workout_session_repository.dart';

class WorkoutSessionRepositoryImpl implements WorkoutSessionRepository {
  WorkoutSessionRepositoryImpl(this._dao);
  final WorkoutSessionDao _dao;

  @override
  Future<List<WorkoutSession>> getAll() async {
    final results = await _dao.getAll();
    return results.map(WorkoutSessionModel.fromDrift).toList();
  }

  @override
  Future<List<WorkoutSession>> getByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final results = await _dao.getByDateRange(start, end);
    return results.map(WorkoutSessionModel.fromDrift).toList();
  }

  @override
  Future<WorkoutSession?> getById(int id) async {
    final result = await _dao.getById(id);
    return result != null ? WorkoutSessionModel.fromDrift(result) : null;
  }

  @override
  Future<WorkoutSession?> getLastSession() async {
    final result = await _dao.getLastSession();
    return result != null ? WorkoutSessionModel.fromDrift(result) : null;
  }

  @override
  Future<int> startSession(WorkoutSession session) {
    return _dao.startSession(
      WorkoutSessionModel.fromEntity(session).toCompanion(),
    );
  }

  @override
  Future<void> endSession(int id, {String? notes, int? rating}) async {
    await _dao.endSession(id, DateTime.now(), notes: notes, rating: rating);
  }

  @override
  Future<void> addSet(WorkoutSet set) {
    return _dao.addSet(WorkoutSetModel.fromEntity(set).toCompanion());
  }

  @override
  Future<void> updateSet(WorkoutSet set) async {
    final model = WorkoutSetModel.fromEntity(set);
    final data = WorkoutSetData(
      id: model.id,
      sessionId: model.sessionId,
      exerciseId: model.exerciseId,
      setNumber: model.setNumber,
      reps: model.reps,
      weight: model.weight,
      isWarmup: model.isWarmup,
      isPR: model.isPR,
      completedAt: model.completedAt,
    );
    await _dao.updateSet(data);
  }

  @override
  Future<void> deleteSet(int id) {
    return _dao.deleteSet(id);
  }

  @override
  Future<void> deleteSession(int sessionId) {
    return _dao.deleteSession(sessionId);
  }

  @override
  Future<List<WorkoutSet>> getSessionSets(int sessionId) async {
    final results = await _dao.getSessionSets(sessionId);
    return results.map(WorkoutSetModel.fromDrift).toList();
  }

  @override
  Future<double> getTotalVolume({int? days}) async {
    // Need to calculate.
    // Fetch sessions in range (if days provided) or all.
    // Then fetch sets for each session? That's N+1.
    // Better: Helper in DAO. But checking DAO, no such helper.
    // Only `getAll` or `getByDateRange`.
    // And `getSessionSets`.
    // This is expensive to do in repo without SQL aggregation.
    // Implementation:
    DateTime? start;
    if (days != null) {
      start = DateTime.now().subtract(Duration(days: days));
    }

    final sessions = start != null
        ? await _dao.getByDateRange(start, DateTime.now())
        : await _dao.getAll();

    double totalVolume = 0;
    for (final session in sessions) {
      // Assuming session has volume field calculated?
      // WorkoutSessionData has `totalVolume`.
      // If it's stored, we just sum it up.
      totalVolume += session.totalVolume;
    }
    return totalVolume;
  }

  @override
  Future<int> getWorkoutCount({int? days}) async {
    if (days == null) {
      final all = await _dao.getAll();
      return all.length;
    }
    final start = DateTime.now().subtract(Duration(days: days));
    final sessions = await _dao.getByDateRange(start, DateTime.now());
    return sessions.length;
  }

  @override
  Future<List<DateTime>> getWorkoutDates({int days = 30}) async {
    final start = DateTime.now().subtract(Duration(days: days));
    final sessions = await _dao.getByDateRange(start, DateTime.now());
    return sessions.map((s) => s.startTime).toList();
  }

  @override
  Stream<WorkoutSession?> watchActiveSession() {
    return _dao.watchActiveSession().map(
      (data) => data != null ? WorkoutSessionModel.fromDrift(data) : null,
    );
  }

  @override
  Stream<List<WorkoutSet>> watchSessionSets(int sessionId) {
    return _dao
        .watchSessionSets(sessionId)
        .map((rows) => rows.map(WorkoutSetModel.fromDrift).toList());
  }
}
