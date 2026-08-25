import 'package:vitalsync/core/di/injection_container.dart';
import 'package:vitalsync/core/enums/achievement_type.dart';
import 'package:vitalsync/core/enums/sync_enums.dart';
import 'package:vitalsync/data/local/daos/fitness/workout_dao.dart';
import 'package:vitalsync/data/local/database.dart';
import 'package:vitalsync/data/models/fitness/achievement_model.dart';
import 'package:vitalsync/domain/entities/fitness/achievement.dart';
import 'package:vitalsync/domain/repositories/fitness/achievement_repository.dart';
import 'package:vitalsync/domain/repositories/fitness/personal_record_repository.dart';
import 'package:vitalsync/domain/repositories/fitness/streak_repository.dart';
import 'package:vitalsync/domain/repositories/fitness/workout_session_repository.dart';
import 'package:vitalsync/domain/repositories/health/medication_log_repository.dart';

class AchievementRepositoryImpl implements AchievementRepository {
  AchievementRepositoryImpl(this._dao, this._database);
  final AchievementDao _dao;
  final AppDatabase _database;

  /// Cloud collection name. Must match the entry in
  /// `SyncService.tablesToSync` and the Lambda's `COLLECTION_PREFIX`.
  static const _collection = 'achievements';

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
    // Get all locked achievements
    final locked = await getLocked();

    if (locked.isEmpty) return;

    // Get required repositories
    final streakRepo = getIt<StreakRepository>();
    final workoutSessionRepo = getIt<WorkoutSessionRepository>();
    final personalRecordRepo = getIt<PersonalRecordRepository>();
    final medicationLogRepo = getIt<MedicationLogRepository>();

    // Check each locked achievement
    for (final achievement in locked) {
      var shouldUnlock = false;

      switch (achievement.type) {
        case AchievementType.streak:
          // Check current streak
          final currentStreak = await streakRepo.getCurrentStreak();
          shouldUnlock = currentStreak >= achievement.requirement;

        case AchievementType.volume:
          // Check total volume lifted
          final totalVolume = await workoutSessionRepo.getTotalVolume();
          shouldUnlock = totalVolume >= achievement.requirement;

        case AchievementType.workouts:
          // Check total workout count
          final allWorkouts = await workoutSessionRepo.getAll();
          final workoutCount = allWorkouts.length;
          shouldUnlock = workoutCount >= achievement.requirement;

        case AchievementType.pr:
          // Check total PR count
          final allPRs = await personalRecordRepo.getAll();
          final prCount = allPRs.length;
          shouldUnlock = prCount >= achievement.requirement;

        case AchievementType.medicationCompliance:
          // Check 7-day compliance rate (100% for all days)
          final complianceRate =
              await medicationLogRepo.getOverallComplianceRate(days: 7);
          // Requirement is typically 7 days of 100% compliance
          shouldUnlock = complianceRate >= 1.0 &&
              achievement.requirement <= 7; // 7 consecutive days

        case AchievementType.consistency:
          // Cross-module: both medication compliance and workout streak
          final complianceRate =
              await medicationLogRepo.getOverallComplianceRate(days: 7);
          final currentStreak = await streakRepo.getCurrentStreak();

          // Unlock if both conditions met for specified days
          shouldUnlock = complianceRate >= 0.9 &&
              currentStreak >= achievement.requirement;
      }

      // Unlock if conditions met
      if (shouldUnlock) {
        await _dao.unlock(achievement.id);

        // Re-read for the timestamp the DAO stamped on the row.
        final unlocked = await _dao.getById(achievement.id);
        if (unlocked == null) continue;
        await _database.addToSyncQueue(
          _collection,
          achievement.id,
          SyncOperation.update,
          {
            ...AchievementModel.fromDrift(unlocked).toJson(),
            // The table has no lastModifiedAt column; unlockedAt is what the
            // pull side compares against, so the push uses it too.
            'lastModifiedAt': unlocked.unlockedAt?.toIso8601String(),
          },
        );
      }
    }
  }

  @override
  Stream<List<Achievement>> watchAll() {
    return _dao.watchAll().map(
      (list) => list.map(AchievementModel.fromDrift).toList(),
    );
  }
}
