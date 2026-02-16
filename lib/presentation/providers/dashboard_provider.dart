/// VitalSync — Dashboard Riverpod Provider.
///
/// Combines health + fitness data for dashboard summary.
/// todayComplianceRate, currentStreak, lastWorkoutInfo,
/// nextMedicationTime, topInsights, weeklyOverviewData.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/fitness/workout_session.dart';
import '../../domain/entities/insights/insight.dart';
import '../../features/fitness/presentation/providers/streak_provider.dart';
import '../../features/fitness/presentation/providers/workout_provider.dart';
import '../../features/health/presentation/providers/medication_log_provider.dart';
import '../../features/health/presentation/providers/medication_provider.dart';
import '../../features/insights/presentation/providers/insight_provider.dart';
import '../../features/insights/presentation/providers/weekly_report_provider.dart';

part 'dashboard_provider.g.dart';

/// Dashboard summary data class
class DashboardSummary {
  const DashboardSummary({
    required this.todayComplianceRate,
    required this.currentStreak,
    required this.lastWorkout,
    required this.nextMedicationTime,
    required this.topInsights,
    required this.weeklyWorkoutCount,
    required this.weeklyComplianceRate,
    required this.healthScore,
  });

  final double todayComplianceRate;
  final int currentStreak;
  final WorkoutSession? lastWorkout;
  final DateTime? nextMedicationTime;
  final List<Insight> topInsights;
  final int weeklyWorkoutCount;
  final double weeklyComplianceRate;
  final double healthScore; // 0-100 from weekly report
}

/// Activity item for unified timeline
class ActivityItem {
  const ActivityItem({
    required this.type,
    required this.timestamp,
    required this.title,
    required this.description,
    this.icon,
  });

  final ActivityType type;
  final DateTime timestamp;
  final String title;
  final String description;
  final String? icon;
}

/// Activity type enum
enum ActivityType { medication, workout, symptom }

/// Provider for dashboard summary
@riverpod
Future<DashboardSummary> dashboardSummary(Ref ref) async {
  // Gather data from all modules
  final todayCompliance = await ref.watch(weeklyComplianceProvider.future);
  final streak = await ref.watch(currentStreakProvider.future);
  final recentWorkouts = await ref.watch(recentWorkoutsProvider.future);
  final todayMeds = await ref.watch(todayMedicationsProvider.future);
  final insights = await ref.watch(activeInsightsProvider.future);
  final weeklyCompliance = await ref.watch(weeklyComplianceProvider.future);

  // Calculate next medication time
  DateTime? nextMedicationTime;
  final now = DateTime.now();

  for (final med in todayMeds) {
    final times = med.times; // JSON array like ["08:00", "20:00"]
    if (times.isEmpty) continue;

    // Parse times and find next upcoming time
    for (final timeStr in times) {
      final parts = timeStr.split(':');
      if (parts.length != 2) continue;

      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;

      final medicationTime = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (medicationTime.isAfter(now)) {
        if (nextMedicationTime == null ||
            medicationTime.isBefore(nextMedicationTime)) {
          nextMedicationTime = medicationTime;
        }
      }
    }
  }

  // Get top 3 insights by priority
  final sortedInsights = insights.toList()
    ..sort((a, b) => b.priority.index.compareTo(a.priority.index));
  final topInsights = sortedInsights.take(3).toList();

  // Count workouts this week (last 7 days)
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final weeklyWorkouts = recentWorkouts
      .where((w) => w.startTime.isAfter(weekStart) && w.endTime != null)
      .length;

  // Get health score from weekly report
  var healthScore = 0.0;
  try {
    final weeklyReport = await ref.watch(weeklyReportProvider.future);
    final crossModule = weeklyReport['cross_module'] as Map<String, dynamic>?;
    healthScore = (crossModule?['health_score'] as num?)?.toDouble() ?? 0.0;
  } catch (e) {
    // If weekly report fails, calculate basic health score
    // Formula: compliance 40% + workout consistency 30% + 30% baseline
    healthScore =
        (weeklyCompliance * 0.4 + (weeklyWorkouts / 7.0) * 0.3 + 0.3) * 100;
    healthScore = healthScore.clamp(0.0, 100.0);
  }

  return DashboardSummary(
    todayComplianceRate: todayCompliance,
    currentStreak: streak,
    lastWorkout: recentWorkouts.isNotEmpty ? recentWorkouts.first : null,
    nextMedicationTime: nextMedicationTime,
    topInsights: topInsights,
    weeklyWorkoutCount: weeklyWorkouts,
    weeklyComplianceRate: weeklyCompliance,
    healthScore: healthScore,
  );
}

/// Provider for recent activity timeline (unified)
@riverpod
Future<List<ActivityItem>> recentActivity(Ref ref) async {
  final activities = <ActivityItem>[];

  // Get recent medication logs
  final logs = await ref.watch(todayLogsProvider.future);
  for (final log in logs) {
    if (log.takenTime != null) {
      activities.add(
        ActivityItem(
          type: ActivityType.medication,
          timestamp: log.takenTime!,
          title: 'Medication Taken',
          description: 'Logged at ${_formatTime(log.takenTime!)}',
          icon: '💊',
        ),
      );
    }
  }

  // Get recent workouts
  final workouts = await ref.watch(recentWorkoutsProvider.future);
  for (final workout in workouts) {
    if (workout.endTime != null) {
      activities.add(
        ActivityItem(
          type: ActivityType.workout,
          timestamp: workout.endTime!,
          title: workout.name,
          description: _formatDuration(
            workout.endTime!.difference(workout.startTime),
          ),
          icon: '🏋️',
        ),
      );
    }
  }

  // Sort by timestamp (most recent first) and take last 5
  activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

  return activities.take(5).toList();
}

// Helper function to format time
String _formatTime(DateTime time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

// Helper function to format duration
String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);

  if (hours > 0) {
    return '${hours}h ${minutes}m';
  }

  return '${minutes}m';
}
