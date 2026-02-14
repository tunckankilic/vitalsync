/// VitalSync — Fitness Module: Progress Providers.
///
/// Riverpod 2.0 providers for progress tracking and statistics
/// with code generation.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../domain/entities/fitness/progress_data.dart';
import '../../../../domain/repositories/fitness/workout_session_repository.dart';

part 'progress_provider.g.dart';

/// Time range options for progress tracking
enum TimeRange { oneWeek, oneMonth, threeMonths, sixMonths, oneYear }

/// Extension to convert TimeRange to days
extension TimeRangeExtension on TimeRange {
  int get days {
    switch (this) {
      case TimeRange.oneWeek:
        return 7;
      case TimeRange.oneMonth:
        return 30;
      case TimeRange.threeMonths:
        return 90;
      case TimeRange.sixMonths:
        return 180;
      case TimeRange.oneYear:
        return 365;
    }
  }
}

/// Progress statistics model
class ProgressStats {
  const ProgressStats({
    required this.workoutCount,
    required this.totalVolume,
    required this.totalDuration,
    required this.averageVolumePerWorkout,
  });

  final int workoutCount;
  final double totalVolume;
  final int totalDuration; // in minutes
  final double averageVolumePerWorkout;
}

/// Weekly statistics model with comparison to previous week
class WeeklyStats {
  const WeeklyStats({
    required this.totalVolume,
    required this.workoutCount,
    required this.volumeChangePercent,
  });

  final double totalVolume;
  final int workoutCount;
  final double volumeChangePercent;
}

/// Provider for the WorkoutSessionRepository instance
@Riverpod(keepAlive: true)
WorkoutSessionRepository progressWorkoutRepository(Ref ref) {
  return getIt<WorkoutSessionRepository>();
}

/// Provider for weekly statistics with comparison to previous week
@riverpod
Future<WeeklyStats> weeklyStats(Ref ref) async {
  final repository = ref.watch(progressWorkoutRepositoryProvider);

  // Get current week data (last 7 days)
  final currentWeekCount = await repository.getWorkoutCount(days: 7);
  final currentWeekVolume = await repository.getTotalVolume(days: 7);

  // Get previous week data (days 8-14)
  final endDate = DateTime.now().subtract(const Duration(days: 7));
  final startDate = endDate.subtract(const Duration(days: 7));
  final previousWeekSessions = await repository.getByDateRange(
    startDate,
    endDate,
  );

  // Calculate previous week volume
  var previousWeekVolume = 0.0;
  for (final session in previousWeekSessions) {
    previousWeekVolume += session.totalVolume;
  }

  // Calculate volume change percentage
  final volumeChangePercent = previousWeekVolume > 0
      ? ((currentWeekVolume - previousWeekVolume) / previousWeekVolume) * 100
      : 0.0;

  return WeeklyStats(
    totalVolume: currentWeekVolume,
    workoutCount: currentWeekCount,
    volumeChangePercent: volumeChangePercent,
  );
}

/// Family provider for progress statistics
@riverpod
Future<ProgressStats> progressStats(Ref ref, TimeRange timeRange) async {
  final repository = ref.watch(progressWorkoutRepositoryProvider);
  final days = timeRange.days;

  // Get data for the time range
  final workoutCount = await repository.getWorkoutCount(days: days);
  final totalVolume = await repository.getTotalVolume(days: days);

  // Get sessions to calculate duration
  final endDate = DateTime.now();
  final startDate = endDate.subtract(Duration(days: days));
  final sessions = await repository.getByDateRange(startDate, endDate);

  var totalDuration = 0;
  for (final session in sessions) {
    if (session.endTime != null) {
      totalDuration += session.endTime!.difference(session.startTime).inMinutes;
    }
  }

  final averageVolumePerWorkout = workoutCount > 0
      ? totalVolume / workoutCount
      : 0.0;

  return ProgressStats(
    workoutCount: workoutCount,
    totalVolume: totalVolume,
    totalDuration: totalDuration,
    averageVolumePerWorkout: averageVolumePerWorkout,
  );
}

/// Family provider for volume chart data
@riverpod
Future<List<ProgressData>> volumeChartData(Ref ref, TimeRange timeRange) async {
  final repository = ref.watch(progressWorkoutRepositoryProvider);
  final days = timeRange.days;

  final endDate = DateTime.now();
  final startDate = endDate.subtract(Duration(days: days));
  final sessions = await repository.getByDateRange(startDate, endDate);

  // Group sessions by date and calculate daily volume
  final volumeByDate = <DateTime, double>{};

  for (final session in sessions) {
    final date = DateTime(
      session.startTime.year,
      session.startTime.month,
      session.startTime.day,
    );

    volumeByDate[date] = (volumeByDate[date] ?? 0.0) + session.totalVolume;
  }

  // Convert to ProgressData list
  final chartData = volumeByDate.entries.map((entry) {
    return ProgressData(
      date: entry.key,
      value: entry.value,
      label: '${entry.value.toStringAsFixed(0)} kg',
    );
  }).toList();

  // Sort by date
  chartData.sort((a, b) => a.date.compareTo(b.date));

  return chartData;
}

/// Family provider for workout frequency data
@riverpod
Future<List<ProgressData>> workoutFrequency(
  Ref ref,
  TimeRange timeRange,
) async {
  final repository = ref.watch(progressWorkoutRepositoryProvider);
  final days = timeRange.days;

  final endDate = DateTime.now();
  final startDate = endDate.subtract(Duration(days: days));
  final sessions = await repository.getByDateRange(startDate, endDate);

  // Group sessions by week
  final workoutsByWeek = <int, int>{};

  for (final session in sessions) {
    // Calculate week number since start date
    final weekNumber = session.startTime.difference(startDate).inDays ~/ 7;
    workoutsByWeek[weekNumber] = (workoutsByWeek[weekNumber] ?? 0) + 1;
  }

  // Convert to ProgressData list
  final chartData = workoutsByWeek.entries.map((entry) {
    final weekStart = startDate.add(Duration(days: entry.key * 7));
    return ProgressData(
      date: weekStart,
      value: entry.value.toDouble(),
      label: '${entry.value} workouts',
    );
  }).toList();

  // Sort by date
  chartData.sort((a, b) => a.date.compareTo(b.date));

  return chartData;
}

/// Family provider for exercise-specific progress
@riverpod
Future<List<ProgressData>> exerciseProgress(Ref ref, int exerciseId) async {
  final repository = ref.watch(progressWorkoutRepositoryProvider);

  // Get all sessions (for the past year)
  final endDate = DateTime.now();
  final startDate = endDate.subtract(const Duration(days: 365));
  final sessions = await repository.getByDateRange(startDate, endDate);

  // For each session, get sets for the specific exercise
  final progressData = <ProgressData>[];

  for (final session in sessions) {
    final sets = await repository.getSessionSets(session.id);
    final exerciseSets = sets
        .where((s) => s.exerciseId == exerciseId && !s.isWarmup)
        .toList();

    if (exerciseSets.isNotEmpty) {
      // Find max weight for this session
      final maxWeight = exerciseSets
          .map((s) => s.weight)
          .reduce((a, b) => a > b ? a : b);

      progressData.add(
        ProgressData(
          date: session.startTime,
          value: maxWeight,
          label: '${maxWeight.toStringAsFixed(1)} kg',
        ),
      );
    }
  }

  // Sort by date
  progressData.sort((a, b) => a.date.compareTo(b.date));

  return progressData;
}
