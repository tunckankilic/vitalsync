import 'package:vitalsync/core/enums/achievement_type.dart';
import 'package:vitalsync/domain/entities/fitness/achievement.dart';

import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../domain/repositories/fitness/achievement_repository.dart';
import '../../../../domain/repositories/fitness/workout_session_repository.dart';
import '../../../../domain/repositories/health/medication_log_repository.dart';

class AchievementService {
  AchievementService({
    required AchievementRepository achievementRepository,
    required WorkoutSessionRepository workoutRepository,
    required MedicationLogRepository medicationLogRepository,
    required NotificationService notificationService,
    required AnalyticsService analyticsService,
  }) : _achievementRepository = achievementRepository,
       _workoutRepository = workoutRepository,
       _medicationLogRepository = medicationLogRepository,
       _notificationService = notificationService,
       _analyticsService = analyticsService;

  final AchievementRepository _achievementRepository;
  final WorkoutSessionRepository _workoutRepository;
  final MedicationLogRepository _medicationLogRepository;
  final NotificationService _notificationService;
  final AnalyticsService _analyticsService;

  /// Main entry point to check all achievement categories.
  Future<void> checkAndUnlockAchievements() async {
    await Future.wait([
      checkWorkoutAchievements(),
      checkHealthAchievements(),
      checkCrossModuleAchievements(),
    ]);
  }

  /// Check and unlock workout-related achievements.
  Future<void> checkWorkoutAchievements() async {
    final allAchievements = await _achievementRepository.getAll();
    final lockedWorkoutAchievements = allAchievements
        .where((a) => a.unlockedAt == null && _isWorkoutAchievement(a.type))
        .toList();

    for (final achievement in lockedWorkoutAchievements) {
      final shouldUnlock = await _checkWorkoutAchievementCriteria(achievement);
      if (shouldUnlock) {
        await _unlockAchievement(achievement);
      }
    }
  }

  /// Check and unlock health-related achievements.
  Future<void> checkHealthAchievements() async {
    final allAchievements = await _achievementRepository.getAll();
    final lockedHealthAchievements = allAchievements
        .where(
          (a) =>
              a.unlockedAt == null &&
              a.type == AchievementType.medicationCompliance,
        )
        .toList();

    for (final achievement in lockedHealthAchievements) {
      final shouldUnlock = await _checkHealthAchievementCriteria(achievement);
      if (shouldUnlock) {
        await _unlockAchievement(achievement);
      }
    }
  }

  /// Check and unlock cross-module achievements (consistency).
  Future<void> checkCrossModuleAchievements() async {
    final allAchievements = await _achievementRepository.getAll();
    final lockedCrossModuleAchievements = allAchievements
        .where(
          (a) => a.unlockedAt == null && a.type == AchievementType.consistency,
        )
        .toList();

    for (final achievement in lockedCrossModuleAchievements) {
      final shouldUnlock = await _checkCrossModuleAchievementCriteria(
        achievement,
      );
      if (shouldUnlock) {
        await _unlockAchievement(achievement);
      }
    }
  }

  // ========== Private Helper Methods ==========

  /// Check if achievement type is workout-related.
  bool _isWorkoutAchievement(AchievementType type) {
    return type == AchievementType.streak ||
        type == AchievementType.volume ||
        type == AchievementType.workouts ||
        type == AchievementType.pr;
  }

  /// Check if a workout achievement should be unlocked.
  Future<bool> _checkWorkoutAchievementCriteria(Achievement achievement) async {
    switch (achievement.type) {
      case AchievementType.streak:
        return await _checkStreakAchievement(achievement.requirement);
      case AchievementType.volume:
        return await _checkVolumeAchievement(achievement.requirement);
      case AchievementType.workouts:
        return await _checkWorkoutCountAchievement(achievement.requirement);
      case AchievementType.pr:
        // PR achievements are typically unlocked when a PR is set
        // This would require additional logic in workout tracking
        return false;
      default:
        return false;
    }
  }

  /// Check if a health achievement should be unlocked.
  Future<bool> _checkHealthAchievementCriteria(Achievement achievement) async {
    if (achievement.type == AchievementType.medicationCompliance) {
      return await _checkMedicationComplianceAchievement(
        achievement.requirement,
      );
    }
    return false;
  }

  /// Check if a cross-module achievement should be unlocked.
  Future<bool> _checkCrossModuleAchievementCriteria(
    Achievement achievement,
  ) async {
    if (achievement.type == AchievementType.consistency) {
      return await _checkConsistencyAchievement(achievement.requirement);
    }
    return false;
  }

  /// Check workout streak achievement.
  /// Requirement represents consecutive days with workouts.
  Future<bool> _checkStreakAchievement(int requiredDays) async {
    final workoutDates = await _workoutRepository.getWorkoutDates(
      days: requiredDays + 7,
    );

    if (workoutDates.isEmpty) return false;

    // Sort dates in descending order
    final sortedDates = workoutDates.toList()..sort((a, b) => b.compareTo(a));

    // Check for consecutive days starting from most recent
    var currentStreak = 1;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check if there's a workout today or yesterday
    final mostRecentDate = DateTime(
      sortedDates.first.year,
      sortedDates.first.month,
      sortedDates.first.day,
    );

    if (today.difference(mostRecentDate).inDays > 1) {
      return false; // Streak is broken
    }

    for (var i = 0; i < sortedDates.length - 1; i++) {
      final current = DateTime(
        sortedDates[i].year,
        sortedDates[i].month,
        sortedDates[i].day,
      );
      final next = DateTime(
        sortedDates[i + 1].year,
        sortedDates[i + 1].month,
        sortedDates[i + 1].day,
      );

      if (current.difference(next).inDays == 1) {
        currentStreak++;
        if (currentStreak >= requiredDays) {
          return true;
        }
      } else {
        break; // Streak broken
      }
    }

    return currentStreak >= requiredDays;
  }

  /// Check total volume achievement.
  /// Requirement represents total volume in kg.
  Future<bool> _checkVolumeAchievement(int requiredVolume) async {
    final totalVolume = await _workoutRepository.getTotalVolume();
    return totalVolume >= requiredVolume;
  }

  /// Check workout count achievement.
  /// Requirement represents total number of workouts.
  Future<bool> _checkWorkoutCountAchievement(int requiredCount) async {
    final workoutCount = await _workoutRepository.getWorkoutCount();
    return workoutCount >= requiredCount;
  }

  /// Check medication compliance achievement.
  /// Requirement represents compliance percentage (0-100).
  Future<bool> _checkMedicationComplianceAchievement(
    int requiredPercentage,
  ) async {
    final complianceRate = await _medicationLogRepository
        .getOverallComplianceRate(days: 30);
    final compliancePercentage = (complianceRate * 100).round();
    return compliancePercentage >= requiredPercentage;
  }

  /// Check consistency achievement (cross-module).
  /// Requirement represents days of combined workout + medication adherence.
  Future<bool> _checkConsistencyAchievement(int requiredDays) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: requiredDays));

    final workoutDates = await _workoutRepository.getWorkoutDates(
      days: requiredDays,
    );
    final medicationLogs = await _medicationLogRepository.getByDateRange(
      startDate,
      now,
    );

    // Count days with both workout and medication compliance
    var consistentDays = 0;

    for (var i = 0; i < requiredDays; i++) {
      final checkDate = now.subtract(Duration(days: i));
      final dateOnly = DateTime(checkDate.year, checkDate.month, checkDate.day);

      // Check if there's a workout on this day
      final hasWorkout = workoutDates.any((date) {
        final workoutDate = DateTime(date.year, date.month, date.day);
        return workoutDate == dateOnly;
      });

      // Check if there's medication compliance on this day
      final dayLogs = medicationLogs.where((log) {
        final logTime = log.takenTime ?? log.scheduledTime;
        final logDate = DateTime(logTime.year, logTime.month, logTime.day);
        return logDate == dateOnly;
      }).toList();

      final hasMedicationCompliance = dayLogs.isNotEmpty;

      if (hasWorkout && hasMedicationCompliance) {
        consistentDays++;
      }
    }

    return consistentDays >= requiredDays;
  }

  /// Unlock an achievement and trigger notifications/analytics.
  Future<void> _unlockAchievement(Achievement achievement) async {
    // Update in repository
    await _achievementRepository.checkAndUnlock();

    // Send notification using existing notification method
    await _notificationService.showNotification(
      id: 72000 + achievement.id,
      title: 'Achievement Unlocked!',
      body: '${achievement.title} - ${achievement.description}',
      payload: 'achievement:${achievement.id}',
    );

    // Track analytics using existing method
    await _analyticsService.logAchievementUnlocked(
      achievementType: achievement.type.toDbValue(),
      achievementId: achievement.id.toString(),
    );
  }
}
