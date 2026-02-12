/// VitalSync — Workout Utility Functions.
///
/// Volume calculation (sets × reps × weight)
/// 1RM calculation (Brzycki formula)
/// Streak calculation
/// Progress percentage calculation
/// Weekly volume trend calculation
library;

import 'dart:math' as math;

/// Utility functions for workout-related calculations.
///
/// Provides methods for volume, one-rep max, streaks, and progress tracking.
abstract class WorkoutUtils {
  // VOLUME CALCULATIONS

  /// Calculates total volume for a single set.
  ///
  /// Formula: reps × weight
  ///
  /// Example: 10 reps × 100kg = 1000kg volume
  static double calculateSetVolume({
    required int reps,
    required double weight,
  }) {
    return reps * weight;
  }

  /// Calculates total volume for multiple sets.
  ///
  /// Formula: sets × reps × weight
  ///
  /// Example: 3 sets × 10 reps × 100kg = 3000kg total volume
  static double calculateVolume({
    required int sets,
    required int reps,
    required double weight,
  }) {
    return sets * reps * weight;
  }

  /// Calculates total volume from a list of sets.
  ///
  /// Each set in the list should be a map with 'reps' and 'weight' keys.
  ///
  /// Example:
  /// ```dart
  /// final sets = [
  ///   {'reps': 10, 'weight': 100.0},
  ///   {'reps': 8, 'weight': 110.0},
  ///   {'reps': 6, 'weight': 120.0},
  /// ];
  /// final volume = calculateTotalVolume(sets); // 3080.0
  /// ```
  static double calculateTotalVolume(List<Map<String, dynamic>> sets) {
    var total = 0.0;
    for (final set in sets) {
      final reps = set['reps'] as int;
      final weight = set['weight'] as double;
      total += calculateSetVolume(reps: reps, weight: weight);
    }
    return total;
  }

  // ONE REP MAX (1RM) CALCULATIONS

  /// Calculates estimated one-rep max using the Brzycki formula.
  ///
  /// Formula: weight × (36 / (37 - reps))
  ///
  /// This formula is most accurate for reps in the 1-10 range.
  /// Returns the actual weight if reps = 1.
  ///
  /// Example: 100kg × 10 reps = 133.3kg estimated 1RM
  ///
  /// Throws [ArgumentError] if reps <= 0 or reps > 36 (formula limitation).
  static double calculateOneRepMax({
    required double weight,
    required int reps,
  }) {
    if (reps <= 0) {
      throw ArgumentError('Reps must be greater than 0');
    }

    if (reps == 1) {
      return weight; // Actual 1RM
    }

    if (reps > 36) {
      throw ArgumentError(
        'Brzycki formula is not accurate for reps > 36. '
        'Please use a lower rep range.',
      );
    }

    // Brzycki formula: weight × (36 / (37 - reps))
    return weight * (36 / (37 - reps));
  }

  /// Calculates the weight needed to perform a specific number of reps
  /// based on a known 1RM.
  ///
  /// This is the inverse of the Brzycki formula.
  ///
  /// Example: If 1RM is 150kg, weight for 10 reps = 112.5kg
  static double calculateWeightForReps({
    required double oneRepMax,
    required int targetReps,
  }) {
    if (targetReps <= 0) {
      throw ArgumentError('Target reps must be greater than 0');
    }

    if (targetReps == 1) {
      return oneRepMax;
    }

    if (targetReps > 36) {
      throw ArgumentError(
        'Target reps > 36 is not supported by Brzycki formula',
      );
    }

    // Inverse Brzycki: weight = 1RM × ((37 - reps) / 36)
    return oneRepMax * ((37 - targetReps) / 36);
  }

  // STREAK CALCULATIONS

  /// Calculates the current workout streak from a list of workout dates.
  ///
  /// A streak is defined as consecutive days with workouts (no gaps).
  /// The streak includes today if there was a workout today.
  ///
  /// Example:
  /// If workouts on: Feb 10, Feb 11, Feb 12 (today)
  /// → Current streak: 3 days
  ///
  /// If workouts on: Feb 10, Feb 11, and today is Feb 13 (gap)
  /// → Current streak: 0 days
  static int calculateCurrentStreak(List<DateTime> workoutDates) {
    if (workoutDates.isEmpty) return 0;

    // Sort dates in descending order (most recent first)
    final sortedDates = workoutDates.toList()..sort((a, b) => b.compareTo(a));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check if the most recent workout was today or yesterday
    final mostRecentDate = DateTime(
      sortedDates.first.year,
      sortedDates.first.month,
      sortedDates.first.day,
    );

    final daysSinceLastWorkout = today.difference(mostRecentDate).inDays;

    // If last workout was more than 1 day ago, streak is broken
    if (daysSinceLastWorkout > 1) return 0;

    var streak = 0;
    var expectedDate = mostRecentDate;

    for (final date in sortedDates) {
      final workoutDate = DateTime(date.year, date.month, date.day);

      // If this workout is on the expected date, continue streak
      if (workoutDate.isAtSameMomentAs(expectedDate)) {
        streak++;
        expectedDate = expectedDate.subtract(const Duration(days: 1));
      } else if (workoutDate.isBefore(expectedDate)) {
        // Gap detected, streak ends
        break;
      }
      // If workout is after expected date (duplicate day), skip it
    }

    return streak;
  }

  /// Calculates the longest workout streak from a list of workout dates.
  ///
  /// Returns the maximum number of consecutive days with workouts.
  static int calculateLongestStreak(List<DateTime> workoutDates) {
    if (workoutDates.isEmpty) return 0;

    // Sort dates in ascending order
    final sortedDates = workoutDates.toList()..sort((a, b) => a.compareTo(b));

    var longestStreak = 1;
    var currentStreak = 1;

    for (var i = 1; i < sortedDates.length; i++) {
      final prevDate = DateTime(
        sortedDates[i - 1].year,
        sortedDates[i - 1].month,
        sortedDates[i - 1].day,
      );
      final currentDate = DateTime(
        sortedDates[i].year,
        sortedDates[i].month,
        sortedDates[i].day,
      );

      final daysDiff = currentDate.difference(prevDate).inDays;

      if (daysDiff == 1) {
        // Consecutive days
        currentStreak++;
        longestStreak = math.max(longestStreak, currentStreak);
      } else if (daysDiff > 1) {
        // Gap detected, reset current streak
        currentStreak = 1;
      }
      // If daysDiff == 0 (same day), don't increment streak
    }

    return longestStreak;
  }

  // PROGRESS CALCULATIONS

  /// Calculates progress percentage towards a goal.
  ///
  /// Formula: (current / target) × 100
  ///
  /// Returns 100.0 if target is reached or exceeded.
  /// Returns 0.0 if target is 0 or negative.
  ///
  /// Example: current=75, target=100 → 75.0%
  static double calculateProgressPercentage({
    required double current,
    required double target,
  }) {
    if (target <= 0) return 0.0;

    final progress = (current / target) * 100;
    return progress > 100.0 ? 100.0 : progress;
  }

  /// Calculates the percentage change between two values.
  ///
  /// Formula: ((newValue - oldValue) / oldValue) × 100
  ///
  /// Positive = increase, Negative = decrease
  /// Returns 0.0 if oldValue is 0.
  ///
  /// Example: old=100, new=120 → +20.0%
  static double calculatePercentageChange({
    required double oldValue,
    required double newValue,
  }) {
    if (oldValue == 0) return 0.0;

    return ((newValue - oldValue) / oldValue) * 100;
  }

  // TREND ANALYSIS

  /// Analyzes weekly volume trend.
  ///
  /// Takes a list of weekly volume values (most recent last) and returns:
  /// - 'increasing' if trend is upward
  /// - 'decreasing' if trend is downward
  /// - 'stable' if relatively flat
  ///
  /// Requires at least 2 data points.
  ///
  /// Example:
  /// ```dart
  /// final volumes = [5000.0, 5200.0, 5500.0, 5800.0];
  /// final trend = calculateWeeklyVolumeTrend(volumes); // 'increasing'
  /// ```
  static VolumeTrend calculateWeeklyVolumeTrend(
    List<double> weeklyVolumes, {
    double stabilityThreshold = 5.0, // ±5% is considered stable
  }) {
    if (weeklyVolumes.length < 2) {
      return VolumeTrend.stable; // Not enough data
    }

    // Calculate simple moving average slope
    // Compare first half to second half
    final midPoint = weeklyVolumes.length ~/ 2;
    final firstHalf = weeklyVolumes.sublist(0, midPoint);
    final secondHalf = weeklyVolumes.sublist(midPoint);

    final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;

    final changePercent = calculatePercentageChange(
      oldValue: firstAvg,
      newValue: secondAvg,
    );

    if (changePercent.abs() < stabilityThreshold) {
      return VolumeTrend.stable;
    } else if (changePercent > 0) {
      return VolumeTrend.increasing;
    } else {
      return VolumeTrend.decreasing;
    }
  }

  /// Calculates the average weekly volume from a list of weekly volumes.
  static double calculateAverageWeeklyVolume(List<double> weeklyVolumes) {
    if (weeklyVolumes.isEmpty) return 0.0;
    return weeklyVolumes.reduce((a, b) => a + b) / weeklyVolumes.length;
  }

  /// Calculates volume per workout from total volume and workout count.
  static double calculateVolumePerWorkout({
    required double totalVolume,
    required int workoutCount,
  }) {
    if (workoutCount == 0) return 0.0;
    return totalVolume / workoutCount;
  }
}

// ENUMS

/// Represents the trend direction for volume analysis.
enum VolumeTrend {
  /// Volume is increasing over time
  increasing,

  /// Volume is decreasing over time
  decreasing,

  /// Volume is relatively stable (within threshold)
  stable,
}
