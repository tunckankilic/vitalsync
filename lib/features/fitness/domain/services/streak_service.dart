import 'package:vitalsync/domain/repositories/fitness/streak_repository.dart';
import 'package:vitalsync/domain/repositories/fitness/workout_session_repository.dart';

class StreakService {
  StreakService({
    required StreakRepository streakRepository,
    required WorkoutSessionRepository workoutRepository,
  }) : _streakRepository = streakRepository,
       _workoutRepository = workoutRepository;

  final StreakRepository _streakRepository;
  final WorkoutSessionRepository _workoutRepository;

  Future<void> updateStreak() async {
    // Get workout dates from the last 30 days to check streak
    final workoutDates = await _workoutRepository.getWorkoutDates(days: 30);

    if (workoutDates.isEmpty) {
      // No workouts, streak is broken
      await _streakRepository.updateStreak();
      return;
    }

    // Normalize dates to midnight for comparison
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);
    final yesterdayNormalized = todayNormalized.subtract(
      const Duration(days: 1),
    );

    // Normalize workout dates
    final normalizedWorkoutDates = workoutDates.map((date) {
      return DateTime(date.year, date.month, date.day);
    }).toSet();

    // Check if there's a workout today or yesterday to maintain streak
    final hasWorkoutToday = normalizedWorkoutDates.contains(todayNormalized);
    final hasWorkoutYesterday = normalizedWorkoutDates.contains(
      yesterdayNormalized,
    );

    // Streak continues if there's a workout today or yesterday
    if (hasWorkoutToday || hasWorkoutYesterday) {
      await _streakRepository.updateStreak();
    } else {
      // Streak is broken, reset it
      await _streakRepository.updateStreak();
    }
  }

  Future<int> getCurrentStreak() async {
    return _streakRepository.getCurrentStreak();
  }

  Future<int> getLongestStreak() async {
    return _streakRepository.getLongestStreak();
  }

  Future<bool> isStreakActiveToday() async {
    // Get recent workout dates
    final workoutDates = await _workoutRepository.getWorkoutDates(days: 7);

    if (workoutDates.isEmpty) {
      return false;
    }

    // Normalize today's date to midnight
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);

    // Check if any workout date matches today
    return workoutDates.any((date) {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      return normalizedDate == todayNormalized;
    });
  }
}
