import 'package:vitalsync/core/enums/sync_enums.dart';
import 'package:vitalsync/data/local/daos/fitness/workout_dao.dart';
import 'package:vitalsync/data/local/database.dart';
import 'package:vitalsync/data/models/fitness/workout_session_model.dart';
import 'package:vitalsync/data/models/fitness/workout_set_model.dart';
import 'package:vitalsync/domain/entities/fitness/workout_session.dart';
import 'package:vitalsync/domain/entities/fitness/workout_set.dart';
import 'package:vitalsync/domain/repositories/fitness/workout_session_repository.dart';

class WorkoutSessionRepositoryImpl implements WorkoutSessionRepository {
  WorkoutSessionRepositoryImpl(this._dao, this._database);
  final WorkoutSessionDao _dao;
  final AppDatabase _database;

  /// Cloud collection names. Must match the entries in
  /// `SyncService.tablesToSync` and the Lambda's `COLLECTION_PREFIX`.
  static const _sessionCollection = 'workout_sessions';
  static const _setCollection = 'workout_sets';

  /// Queues the current state of a session. Sessions are edited in place
  /// (started, then ended, then possibly re-rated), so the row is re-read
  /// rather than reconstructed from the caller's argument.
  Future<void> _enqueueSession(int id, SyncOperation operation) async {
    final row = await _dao.getById(id);
    if (row == null) return;
    await _database.addToSyncQueue(
      _sessionCollection,
      id,
      operation,
      WorkoutSessionModel.fromDrift(row).toJson(),
    );
  }

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
  Future<int> startSession(WorkoutSession session) async {
    final id = await _dao.startSession(
      WorkoutSessionModel.fromEntity(session).toCompanion(),
    );
    await _enqueueSession(id, SyncOperation.insert);
    return id;
  }

  @override
  Future<void> endSession(
    int id, {
    String? notes,
    int? rating,
    double? totalVolume,
  }) async {
    await _dao.endSession(
      id,
      DateTime.now(),
      notes: notes,
      rating: rating,
      totalVolume: totalVolume,
    );
    await _enqueueSession(id, SyncOperation.update);
  }

  @override
  Future<void> addSet(WorkoutSet set) async {
    final model = WorkoutSetModel.fromEntity(set);
    final id = await _dao.addSet(model.toCompanion());
    await _database.addToSyncQueue(
      _setCollection,
      id,
      SyncOperation.insert,
      // The row carries the auto-assigned id, which the caller's set does
      // not; everything else is the caller's.
      {...model.toJson(), 'id': id},
    );

    // A set changes the session's volume, so the session is stale in the
    // cloud until it is pushed again.
    await _enqueueSession(set.sessionId, SyncOperation.update);
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
    await _database.addToSyncQueue(
      _setCollection,
      model.id,
      SyncOperation.update,
      model.toJson(),
    );
    await _enqueueSession(set.sessionId, SyncOperation.update);
  }

  @override
  Future<void> deleteSet(int id) async {
    // Read the owning session before the row is gone, so its volume can be
    // pushed again afterwards.
    final existing = await _dao.getSetById(id);
    await _dao.deleteSet(id);
    await _database.addToSyncQueue(
      _setCollection,
      id,
      SyncOperation.delete,
      const {},
    );
    if (existing != null) {
      await _enqueueSession(existing.sessionId, SyncOperation.update);
    }
  }

  @override
  Future<void> deleteSession(int sessionId) async {
    // The sets go with the session locally (cascade), so each one is queued
    // for removal too — otherwise they would be pulled back on the next
    // sync from a device that still has them.
    final sets = await _dao.getSessionSets(sessionId);
    await _dao.deleteSession(sessionId);

    for (final set in sets) {
      await _database.addToSyncQueue(
        _setCollection,
        set.id,
        SyncOperation.delete,
        const {},
      );
    }
    await _database.addToSyncQueue(
      _sessionCollection,
      sessionId,
      SyncOperation.delete,
      const {},
    );
  }

  @override
  Future<void> closeOpenSessions() async {
    await _dao.closeOpenSessions(DateTime.now());
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
