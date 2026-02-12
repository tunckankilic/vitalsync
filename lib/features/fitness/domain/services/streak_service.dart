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
    // TODO: Implement logic
  }

  Future<int> getCurrentStreak() async {
    return _streakRepository.getCurrentStreak();
  }

  Future<int> getLongestStreak() async {
    return _streakRepository.getLongestStreak();
  }

  Future<bool> isStreakActiveToday() async {
    // TODO: Implement logic
    return false;
  }
}
