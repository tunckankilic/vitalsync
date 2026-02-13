/// VitalSync — Workout Rating Enum.
///
/// User rating for workout sessions.
library;

/// Rating scale for workouts (1-5).
enum WorkoutRating {
  terrible(1),
  bad(2),
  okay(3),
  good(4),
  amazing(5);

  const WorkoutRating(this.value);
  final int value;

  /// Convert from integer value.
  static WorkoutRating fromValue(int value) {
    return WorkoutRating.values.firstWhere(
      (e) => e.value == value,
      orElse: () => WorkoutRating.okay,
    );
  }
}
