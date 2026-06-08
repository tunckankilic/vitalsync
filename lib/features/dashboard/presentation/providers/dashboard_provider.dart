/// VitalSync — Dashboard Module: Summary Provider.
///
/// Aggregates real data from the repositories already registered in the GetIt
/// container into a single immutable [DashboardSummary], exposed through one
/// Riverpod provider. Keeping the dashboard self-contained (it resolves repos
/// from GetIt rather than importing each feature's presentation providers) lets
/// the page render a unified view without coupling to the health/fitness/insight
/// modules, and lets tests override the whole summary from one place.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/enums/medication_log_status.dart';
import '../../../../domain/entities/health/medication.dart';
import '../../../../domain/entities/health/medication_log.dart';
import '../../../../domain/entities/insights/insight.dart';
import '../../../../domain/repositories/fitness/streak_repository.dart';
import '../../../../domain/repositories/fitness/workout_session_repository.dart';
import '../../../../domain/repositories/health/medication_log_repository.dart';
import '../../../../domain/repositories/health/medication_repository.dart';
import '../../../../domain/repositories/insights/insight_repository.dart';

part 'dashboard_provider.g.dart';

/// Immutable snapshot of the data shown on the dashboard.
class DashboardSummary {
  const DashboardSummary({
    required this.todayMedications,
    required this.takenToday,
    required this.totalWorkouts,
    required this.weeklyWorkouts,
    required this.currentStreak,
    required this.healthPercent,
    required this.latestInsight,
  });

  /// Active medications relevant for today.
  final List<Medication> todayMedications;

  /// How many of today's scheduled doses are already marked as taken.
  final int takenToday;

  /// All-time number of completed workout sessions.
  final int totalWorkouts;

  /// Workout sessions in the last 7 days.
  final int weeklyWorkouts;

  /// Current workout streak in days.
  final int currentStreak;

  /// Simple health score (0–100) derived from the 7-day medication
  /// compliance rate.
  final int healthPercent;

  /// Most recently generated active insight, or null when there are none.
  final Insight? latestInsight;
}

/// Aggregates the dashboard data from the registered repositories.
@riverpod
Future<DashboardSummary> dashboardSummary(Ref ref) async {
  final medicationRepository = getIt<MedicationRepository>();
  final medicationLogRepository = getIt<MedicationLogRepository>();
  final workoutRepository = getIt<WorkoutSessionRepository>();
  final streakRepository = getIt<StreakRepository>();
  final insightRepository = getIt<InsightRepository>();

  // Fetch independent sources concurrently.
  final results = await Future.wait([
    medicationRepository.getActive(),
    medicationLogRepository.getTodayLogs(),
    medicationLogRepository.getOverallComplianceRate(days: 7),
    workoutRepository.getWorkoutCount(),
    workoutRepository.getWorkoutCount(days: 7),
    streakRepository.getCurrentStreak(),
    insightRepository.getActive(),
  ]);

  final todayMedications = results[0] as List<Medication>;
  final todayLogs = results[1] as List<MedicationLog>;
  final complianceRate = results[2] as double; // 0.0–1.0
  final totalWorkouts = results[3] as int;
  final weeklyWorkouts = results[4] as int;
  final currentStreak = results[5] as int;
  final activeInsights = results[6] as List<Insight>;

  final takenToday = todayLogs
      .where((log) => log.status == MedicationLogStatus.taken)
      .length;

  final latestInsight = activeInsights.isEmpty
      ? null
      : (activeInsights.toList()
              ..sort((a, b) => b.generatedAt.compareTo(a.generatedAt)))
          .first;

  return DashboardSummary(
    todayMedications: todayMedications,
    takenToday: takenToday,
    totalWorkouts: totalWorkouts,
    weeklyWorkouts: weeklyWorkouts,
    currentStreak: currentStreak,
    healthPercent: (complianceRate * 100).round().clamp(0, 100),
    latestInsight: latestInsight,
  );
}
