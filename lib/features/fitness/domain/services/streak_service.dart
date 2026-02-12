/// VitalSync — Streak Service.
///
/// Calculates and manages workout streaks.
/// Tracks consecutive workout days and longest streaks.
library;

import '../../../../data/repositories/fitness/workout_repository_impl.dart';

/// Service for calculating and tracking workout streaks.
///
/// Determines current and longest workout streaks based on
/// workout session data. Full implementation in later prompts.
class StreakService {
  StreakService({
    required StreakRepositoryImpl streakRepository,
    required WorkoutSessionRepositoryImpl workoutRepository,
  }) : _streakRepository = streakRepository,
       _workoutRepository = workoutRepository;
  final StreakRepositoryImpl _streakRepository;
  final WorkoutSessionRepositoryImpl _workoutRepository;

  /// Updates the current workout streak.
  ///
  /// Should be called after each workout completion.
  Future<void> updateStreak() async {
    // TODO: Implement in later prompts
    // 1. Fetch workout dates
    // 2. Calculate consecutive days
    // 3. Update streak repository
    print('Update streak (placeholder)');
  }

  /// Gets the current active streak.
  Future<int> getCurrentStreak() async {
    // TODO: Implement in later prompts
    return 0;
  }

  /// Gets the longest streak ever achieved.
  Future<int> getLongestStreak() async {
    // TODO: Implement in later prompts
    return 0;
  }

  /// Checks if today's workout maintains the streak.
  Future<bool> isStreakActiveToday() async {
    // TODO: Implement in later prompts
    return false;
  }
}
