/// Helper class for workout summary statistics.
class WorkoutSummary {
  const WorkoutSummary({
    required this.totalWorkouts,
    required this.totalVolume,
    required this.totalDurationMinutes,
    required this.streakDays,
  });
  final int totalWorkouts;
  final double totalVolume;
  final int totalDurationMinutes;
  final int streakDays;
}
