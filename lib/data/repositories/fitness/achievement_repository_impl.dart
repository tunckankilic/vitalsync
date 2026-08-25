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
  /// The four repositories [checkAndUnlock] consults are injected rather
  /// than resolved from the service locator inside the method. Reaching for
  /// GetIt mid-method hid the dependencies from the constructor and made the
  /// unlock rules impossible to test without booting the whole container.
  AchievementRepositoryImpl(
    this._dao,
    this._database, {
    required StreakRepository streakRepository,
    required WorkoutSessionRepository workoutRepository,
    required PersonalRecordRepository personalRecordRepository,
    required MedicationLogRepository medicationLogRepository,
  }) : _streakRepository = streakRepository,
       _workoutRepository = workoutRepository,
       _personalRecordRepository = personalRecordRepository,
       _medicationLogRepository = medicationLogRepository;

  final AchievementDao _dao;
  final AppDatabase _database;
  final StreakRepository _streakRepository;
  final WorkoutSessionRepository _workoutRepository;
  final PersonalRecordRepository _personalRecordRepository;
  final MedicationLogRepository _medicationLogRepository;

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

    // Check each locked achievement
    for (final achievement in locked) {
      var shouldUnlock = false;

      switch (achievement.type) {
        case AchievementType.streak:
          // Check current streak
          final currentStreak = await _streakRepository.getCurrentStreak();
          shouldUnlock = currentStreak >= achievement.requirement;

        case AchievementType.volume:
          // Check total volume lifted
          final totalVolume = await _workoutRepository.getTotalVolume();
          shouldUnlock = totalVolume >= achievement.requirement;

        case AchievementType.workouts:
          // Check total workout count
          final allWorkouts = await _workoutRepository.getAll();
          final workoutCount = allWorkouts.length;
          shouldUnlock = workoutCount >= achievement.requirement;

        case AchievementType.pr:
          // Check total PR count
          final allPRs = await _personalRecordRepository.getAll();
          final prCount = allPRs.length;
          shouldUnlock = prCount >= achievement.requirement;

        case AchievementType.medicationCompliance:
          // The requirement is the number of days that must be at 100%, as
          // each achievement's own description says ("... for 1 day",
          // "... for 7 days", "... for 30 days"), so the window is measured
          // over exactly that many days.
          //
          // This used to read a fixed 7-day window and gate on
          // `requirement <= 7`, which made the 30-day achievement
          // permanently unobtainable and unlocked the 1-day one only after
          // a full compliant week.
          final complianceRate = await _medicationLogRepository
              .getOverallComplianceRate(days: achievement.requirement);
          shouldUnlock = complianceRate >= 1.0;

        case AchievementType.consistency:
          // Cross-module: both medication compliance and workout streak.
          //
          // One rule covers all three consistency achievements — they differ
          // only in `requirement`, read as the streak length in days. Their
          // descriptions used to name three different measures (workouts in
          // a week, streak days, total workouts), which this single integer
          // cannot express; the descriptions were corrected to match this
          // check rather than the behaviour changed, because the unlock
          // rule is what shipped and users have progress against it. See
          // the v2 → v3 migration.
          final complianceRate =
              await _medicationLogRepository.getOverallComplianceRate(days: 7);
          final currentStreak = await _streakRepository.getCurrentStreak();

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
