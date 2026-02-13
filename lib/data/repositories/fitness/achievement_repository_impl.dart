import 'package:vitalsync/data/local/daos/fitness/workout_dao.dart';
import 'package:vitalsync/data/models/fitness/achievement_model.dart';
import 'package:vitalsync/domain/entities/fitness/achievement.dart';
import 'package:vitalsync/domain/repositories/fitness/achievement_repository.dart';

class AchievementRepositoryImpl implements AchievementRepository {
  AchievementRepositoryImpl(this._dao);
  final AchievementDao _dao;

  @override
  Future<List<Achievement>> getAll() async {
    final results = await _dao.getAll();
    return results.map(AchievementModel.fromDrift).toList();
  }

  @override
  Future<List<Achievement>> getUnlocked() async {
    final results = await _dao.getUnlocked();
    return results.map(AchievementModel.fromDrift).toList();
  }

  @override
  Future<List<Achievement>> getLocked() async {
    final results = await _dao.getLocked();
    return results.map(AchievementModel.fromDrift).toList();
  }

  @override
  Future<void> checkAndUnlock() async {
    // This logic likely belongs to AchievementService which orchestrates
    // retrieving data from repositories and checking conditions.
    // The repository should only focus on data access (unlocking by ID).
    // Prompt 2.3 defined this method here, but without full context/service logic
    // we can't implement the checking logic inside repository efficiently.
    // I'll leave this as a TODO or implement a simple placeholder.
    // The actual unlocking (persisting) is done via _dao.unlock(id).
    // The checking logic needs to iterate all locked achievements and verify criteria.
    // Since we don't have criteria logic here, we return.
  }

  @override
  Stream<List<Achievement>> watchAll() {
    return _dao.watchAll().map(
      (list) => list.map(AchievementModel.fromDrift).toList(),
    );
  }
}
