/// VitalSync — Fitness Module: Streak Providers.
///
/// Riverpod 2.0 providers for workout streak tracking
/// with code generation.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../domain/repositories/fitness/streak_repository.dart';

part 'streak_provider.g.dart';

/// Provider for the StreakRepository instance
@Riverpod(keepAlive: true)
StreakRepository streakRepository(Ref ref) {
  return getIt<StreakRepository>();
}

/// Provider for current workout streak
@riverpod
Future<int> currentStreak(Ref ref) async {
  final repository = ref.watch(streakRepositoryProvider);
  return repository.getCurrentStreak();
}

/// Provider for longest workout streak
@riverpod
Future<int> longestStreak(Ref ref) async {
  final repository = ref.watch(streakRepositoryProvider);
  return repository.getLongestStreak();
}

/// Family provider for calendar data
/// Returns a map of dates to boolean indicating if workout was done
@riverpod
Future<Map<DateTime, bool>> calendarData(Ref ref, DateTime month) async {
  final repository = ref.watch(streakRepositoryProvider);
  return repository.getCalendarData(month);
}

/// Provider for workout dates (last 30 days)
@riverpod
Future<List<DateTime>> workoutDates(Ref ref) async {
  final repository = ref.watch(streakRepositoryProvider);
  return repository.getWorkoutDates(days: 30);
}
