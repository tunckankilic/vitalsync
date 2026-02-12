import 'exercise.dart';
import 'workout_set.dart';

/// Helper class to group sets by exercise for UI display.
class ExerciseSet {
  const ExerciseSet({required this.exercise, required this.sets});
  final Exercise exercise;
  final List<WorkoutSet> sets;

  ExerciseSet copyWith({Exercise? exercise, List<WorkoutSet>? sets}) {
    return ExerciseSet(
      exercise: exercise ?? this.exercise,
      sets: sets ?? this.sets,
    );
  }
}
