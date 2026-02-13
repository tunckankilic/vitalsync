/// VitalSync — Weekly Report Service.
///
/// Generates comprehensive weekly reports aggregating health and fitness data.
///
/// Report includes:
/// 1. Health Summary: Compliance, trends, symptoms
/// 2. Fitness Summary: Workouts, volume, PRs, streaks
/// 3. Cross-Module Highlights: Health score, best day, top insights
/// 4. Next Week Suggestions: Actionable recommendations
library;

import 'dart:developer' show log;

import 'package:vitalsync/core/enums/insight_category.dart';
import 'package:vitalsync/core/enums/medication_log_status.dart';
import 'package:vitalsync/core/enums/trend_direction.dart';
import 'package:vitalsync/domain/entities/fitness/personal_record.dart';
import 'package:vitalsync/domain/entities/health/medication_log.dart';
import 'package:vitalsync/domain/entities/insights/insight.dart';
import 'package:vitalsync/domain/entities/insights/weekly_report.dart';
import 'package:vitalsync/domain/repositories/fitness/personal_record_repository.dart';
import 'package:vitalsync/domain/repositories/fitness/streak_repository.dart';
import 'package:vitalsync/domain/repositories/fitness/workout_session_repository.dart';
import 'package:vitalsync/domain/repositories/health/medication_log_repository.dart';
import 'package:vitalsync/domain/repositories/health/symptom_repository.dart';
import 'package:vitalsync/domain/repositories/insights/insight_repository.dart';

class WeeklyReportService {
  WeeklyReportService({
    required MedicationLogRepository medicationLogRepository,
    required WorkoutSessionRepository workoutRepository,
    required SymptomRepository symptomRepository,
    required InsightRepository insightRepository,
    required PersonalRecordRepository personalRecordRepository,
    required StreakRepository streakRepository,
  }) : _medicationLogRepository = medicationLogRepository,
       _workoutRepository = workoutRepository,
       _symptomRepository = symptomRepository,
       _insightRepository = insightRepository,
       _personalRecordRepository = personalRecordRepository,
       _streakRepository = streakRepository;

  final MedicationLogRepository _medicationLogRepository;
  final WorkoutSessionRepository _workoutRepository;
  final SymptomRepository _symptomRepository;
  final InsightRepository _insightRepository;
  final PersonalRecordRepository _personalRecordRepository;
  final StreakRepository _streakRepository;

  // ── Public API ──────────────────────────────────────────────────────

  /// Generates a comprehensive weekly report for the current week.
  ///
  /// Automatically calculates the start of the current week (Monday).
  Future<Map<String, dynamic>> generateCurrentWeekReport() async {
    final now = DateTime.now();
    final weekStart = _getWeekStart(now);
    final report = await generateReport(weekStart);
    return report.toJson();
  }

  /// Retrieves the previous week's report.
  ///
  /// Returns null if no data exists for the previous week.
  Future<Map<String, dynamic>?> getPreviousWeekReport() async {
    final now = DateTime.now();
    final currentWeekStart = _getWeekStart(now);
    final previousWeekStart = currentWeekStart.subtract(
      const Duration(days: 7),
    );

    try {
      final report = await generateReport(previousWeekStart);
      return report.toJson();
    } catch (e) {
      log(
        'Error generating previous week report: $e',
        name: 'WeeklyReportService',
      );
      return null;
    }
  }

  /// Generates a comprehensive weekly report for the week starting at [weekStart].
  ///
  /// The report includes health summary, fitness summary, cross-module highlights,
  /// and actionable suggestions for the next week.
  ///
  /// [weekStart] should be the start of a week (typically a Monday).
  Future<WeeklyReport> generateReport(DateTime weekStart) async {
    try {
      final weekEnd = weekStart.add(const Duration(days: 7));
      final previousWeekStart = weekStart.subtract(const Duration(days: 7));
      final now = DateTime.now();

      log(
        'Generating weekly report for $weekStart to $weekEnd',
        name: 'WeeklyReportService',
      );

      // ── 1. Health Summary ────────────────────────────────────────────
      final healthData = await _calculateHealthSummary(
        weekStart,
        weekEnd,
        previousWeekStart,
      );

      // ── 2. Fitness Summary ───────────────────────────────────────────
      final fitnessData = await _calculateFitnessSummary(
        weekStart,
        weekEnd,
        previousWeekStart,
      );

      // ── 3. Cross-Module Highlights ───────────────────────────────────
      final crossData = await _calculateCrossModuleHighlights(
        weekStart,
        weekEnd,
        healthData.compliance,
        fitnessData.workoutCount,
      );

      // ── 4. Next Week Suggestions ─────────────────────────────────────
      final suggestions = await _generateSuggestions(healthData, fitnessData);

      return WeeklyReport(
        startDate: weekStart,
        endDate: weekEnd,
        generatedAt: now,
        // Health Summary
        medicationCompliance: healthData.compliance,
        complianceTrendVsPrevious: healthData.complianceTrend,
        missedMedicationsCount: healthData.missedCount,
        mostProblematicTimeSlot: healthData.problematicTimeSlot,
        symptomsLoggedCount: healthData.symptomCount,
        mostFrequentSymptom: healthData.mostFrequentSymptom,
        // Fitness Summary
        workoutCount: fitnessData.workoutCount,
        totalVolume: fitnessData.totalVolume,
        volumeTrendVsPrevious: fitnessData.volumeTrend,
        totalWorkoutDuration: fitnessData.totalDuration,
        newPRs: fitnessData.newPRs,
        currentStreak: fitnessData.currentStreak,
        // Cross-Module Highlights
        bestDay: crossData.bestDay,
        healthScore: crossData.healthScore,
        topInsights: crossData.topInsights,
        // Suggestions
        suggestions: suggestions,
      );
    } catch (e, stack) {
      log(
        'Error generating weekly report: $e',
        name: 'WeeklyReportService',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  // ── Helper Methods ──────────────────────────────────────────────────

  /// Calculates health summary for the given week.
  Future<_HealthSummaryData> _calculateHealthSummary(
    DateTime weekStart,
    DateTime weekEnd,
    DateTime previousWeekStart,
  ) async {
    // Get medication logs for current week
    final currentWeekLogs = await _medicationLogRepository.getByDateRange(
      weekStart,
      weekEnd,
    );

    // Get previous week logs for trend calculation
    final previousWeekLogs = await _medicationLogRepository.getByDateRange(
      previousWeekStart,
      weekStart,
    );

    // Calculate compliance rate
    final currentCompliance = _calculateComplianceRate(currentWeekLogs);
    final previousCompliance = _calculateComplianceRate(previousWeekLogs);
    final complianceTrend = _calculateTrend(
      currentCompliance,
      previousCompliance,
    );

    // Count missed medications
    final missedCount = currentWeekLogs
        .where((log) => log.status != MedicationLogStatus.taken)
        .length;

    // Find most problematic time slot
    final problematicTimeSlot = _getMostProblematicTimeSlot(currentWeekLogs);

    // Get symptom data
    final symptoms = await _symptomRepository.getByDateRange(
      weekStart,
      weekEnd,
    );
    final symptomCount = symptoms.length;
    final mostFrequentSymptom = _getMostFrequentSymptom(symptoms);

    return _HealthSummaryData(
      compliance: currentCompliance,
      complianceTrend: complianceTrend,
      missedCount: missedCount,
      problematicTimeSlot: problematicTimeSlot,
      symptomCount: symptomCount,
      mostFrequentSymptom: mostFrequentSymptom,
    );
  }

  /// Calculates fitness summary for the given week.
  Future<_FitnessSummaryData> _calculateFitnessSummary(
    DateTime weekStart,
    DateTime weekEnd,
    DateTime previousWeekStart,
  ) async {
    // Get workout sessions for current week
    final currentWeekSessions = await _workoutRepository.getByDateRange(
      weekStart,
      weekEnd,
    );

    // Get previous week sessions for trend calculation
    final previousWeekSessions = await _workoutRepository.getByDateRange(
      previousWeekStart,
      weekStart,
    );

    // Calculate volume
    final currentVolume = currentWeekSessions.fold<double>(
      0.0,
      (sum, session) => sum + session.totalVolume,
    );
    final previousVolume = previousWeekSessions.fold<double>(
      0.0,
      (sum, session) => sum + session.totalVolume,
    );
    final volumeTrend = _calculateTrend(currentVolume, previousVolume);

    // Calculate total duration
    final totalDuration = currentWeekSessions.fold<int>(0, (sum, session) {
      if (session.endTime != null) {
        final duration = session.endTime!.difference(session.startTime);
        return sum + duration.inMinutes;
      }
      return sum;
    });

    // Get new PRs achieved this week
    final allPRs = await _personalRecordRepository.getRecent(limit: 100);
    final newPRs = allPRs
        .where(
          (pr) =>
              pr.achievedAt.isAfter(weekStart) &&
              pr.achievedAt.isBefore(weekEnd),
        )
        .toList();

    // Get current streak
    final currentStreak = await _streakRepository.getCurrentStreak();

    return _FitnessSummaryData(
      workoutCount: currentWeekSessions.length,
      totalVolume: currentVolume,
      volumeTrend: volumeTrend,
      totalDuration: totalDuration,
      newPRs: newPRs,
      currentStreak: currentStreak,
    );
  }

  /// Calculates cross-module highlights.
  Future<_CrossModuleData> _calculateCrossModuleHighlights(
    DateTime weekStart,
    DateTime weekEnd,
    double complianceRate,
    int workoutCount,
  ) async {
    // Find best day (day with both 100% compliance AND workout)
    final bestDay = await _findBestDay(weekStart, weekEnd);

    // Calculate health score
    final healthScore = await _calculateHealthScore(
      weekStart,
      weekEnd,
      complianceRate,
      workoutCount,
    );

    // Get top 3 insights by priority
    final allInsights = await _insightRepository.getActive();
    final crossModuleInsights = allInsights
        .where((i) => i.category == InsightCategory.crossModule)
        .toList();
    final otherInsights = allInsights
        .where((i) => i.category != InsightCategory.crossModule)
        .toList();

    // Prioritize cross-module insights, then sort by priority
    final topInsights = [
      ...crossModuleInsights,
      ...otherInsights,
    ].take(3).toList();

    return _CrossModuleData(
      bestDay: bestDay,
      healthScore: healthScore,
      topInsights: topInsights,
    );
  }

  /// Generates actionable suggestions for next week.
  Future<List<String>> _generateSuggestions(
    _HealthSummaryData healthData,
    _FitnessSummaryData fitnessData,
  ) async {
    final suggestions = <String>[];

    // Compliance-based suggestions
    if (healthData.compliance < 0.80) {
      if (healthData.problematicTimeSlot != null) {
        suggestions.add(
          'Your medication adherence drops during '
          '${healthData.problematicTimeSlot} — consider adjusting '
          'your reminder times.',
        );
      } else {
        suggestions.add(
          'Your medication compliance was ${(healthData.compliance * 100).round()}% '
          'this week — try setting more reminders to improve adherence.',
        );
      }
    }

    // Volume plateau suggestion
    if (fitnessData.volumeTrend == TrendDirection.same &&
        fitnessData.workoutCount >= 3) {
      suggestions.add(
        'Your workout volume has been steady — try progressive overload '
        'this week to continue making gains.',
      );
    }

    // Low workout suggestion
    if (fitnessData.workoutCount < 2) {
      suggestions.add(
        'You had ${fitnessData.workoutCount} workout(s) this week — '
        'aim for at least 3-4 sessions for optimal results.',
      );
    }

    // Symptom suggestion
    if (healthData.symptomCount > 5 && healthData.mostFrequentSymptom != null) {
      suggestions.add(
        'You logged ${healthData.symptomCount} symptoms this week, '
        'with ${healthData.mostFrequentSymptom} being most common — '
        'consider discussing this pattern with your doctor.',
      );
    }

    // Positive reinforcement
    if (healthData.compliance >= 0.95 && fitnessData.workoutCount >= 3) {
      suggestions.add(
        'Excellent balance between health and fitness! '
        'Keep up the great routine.',
      );
    }

    return suggestions;
  }

  // ── Calculation Helpers ─────────────────────────────────────────────

  /// Calculates compliance rate from medication logs.
  double _calculateComplianceRate(List<MedicationLog> logs) {
    if (logs.isEmpty) return 0.0;
    final takenCount = logs
        .where((log) => log.status == MedicationLogStatus.taken)
        .length;
    return takenCount / logs.length;
  }

  /// Calculates trend direction by comparing current and previous values.
  TrendDirection _calculateTrend(double current, double previous) {
    if (previous == 0) return TrendDirection.same;
    final percentChange = ((current - previous) / previous).abs();
    if (percentChange < 0.05) return TrendDirection.same; // Within 5%
    return current > previous ? TrendDirection.up : TrendDirection.down;
  }

  /// Identifies the most problematic time slot for medication compliance.
  String? _getMostProblematicTimeSlot(List<MedicationLog> logs) {
    if (logs.isEmpty) return null;

    final morningLogs = logs.where(
      (log) => log.scheduledTime.hour >= 6 && log.scheduledTime.hour < 12,
    );
    final afternoonLogs = logs.where(
      (log) => log.scheduledTime.hour >= 12 && log.scheduledTime.hour < 18,
    );
    final eveningLogs = logs.where(
      (log) => log.scheduledTime.hour >= 18 || log.scheduledTime.hour < 6,
    );

    final morningCompliance = _calculateComplianceRate(morningLogs.toList());
    final afternoonCompliance = _calculateComplianceRate(
      afternoonLogs.toList(),
    );
    final eveningCompliance = _calculateComplianceRate(eveningLogs.toList());

    // Find the lowest compliance rate
    final rates = {
      'morning': morningCompliance,
      'afternoon': afternoonCompliance,
      'evening': eveningCompliance,
    };

    if (rates.values.every((rate) => rate == 0)) return null;

    final worst = rates.entries.reduce((a, b) => a.value < b.value ? a : b);

    // Only return if significantly worse (more than 20% difference)
    if (worst.value < 0.70) return worst.key;
    return null;
  }

  /// Finds the most frequent symptom from a list.
  String? _getMostFrequentSymptom(List<dynamic> symptoms) {
    if (symptoms.isEmpty) return null;

    final frequency = <String, int>{};
    for (final symptom in symptoms) {
      final name = symptom.name as String;
      frequency[name] = (frequency[name] ?? 0) + 1;
    }

    if (frequency.isEmpty) return null;

    final mostFrequent = frequency.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );

    return mostFrequent.key;
  }

  /// Finds the best day (both 100% compliance AND workout).
  Future<DateTime?> _findBestDay(DateTime weekStart, DateTime weekEnd) async {
    final logs = await _medicationLogRepository.getByDateRange(
      weekStart,
      weekEnd,
    );
    final sessions = await _workoutRepository.getByDateRange(
      weekStart,
      weekEnd,
    );

    // Group logs by date
    final logsByDate = <String, List<MedicationLog>>{};
    for (final log in logs) {
      final dateKey = _dateKey(log.scheduledTime);
      logsByDate.putIfAbsent(dateKey, () => []);
      logsByDate[dateKey]!.add(log);
    }

    // Find compliant days
    final compliantDays = <String>{};
    for (final entry in logsByDate.entries) {
      final allTaken = entry.value.every(
        (log) => log.status == MedicationLogStatus.taken,
      );
      if (allTaken) compliantDays.add(entry.key);
    }

    // Find workout days
    final workoutDays = sessions.map((s) => _dateKey(s.startTime)).toSet();

    // Find intersection (days with both)
    final bestDays = compliantDays.intersection(workoutDays);
    if (bestDays.isEmpty) return null;

    // Return the first best day
    final bestDayStr = bestDays.first;
    final parts = bestDayStr.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  /// Calculates overall health score (0-100).
  ///
  /// Formula: compliance (40%) + workout consistency (30%) + symptom severity inverse (30%)
  Future<double> _calculateHealthScore(
    DateTime weekStart,
    DateTime weekEnd,
    double complianceRate,
    int workoutCount,
  ) async {
    // Compliance score (40% weight)
    final complianceScore = complianceRate * 40;

    // Workout consistency score (30% weight)
    // Ideal: 4 workouts per week = 100% of 30 points
    final workoutConsistency = (workoutCount / 4).clamp(0.0, 1.0);
    final workoutScore = workoutConsistency * 30;

    // Symptom severity inverse score (30% weight)
    final symptoms = await _symptomRepository.getByDateRange(
      weekStart,
      weekEnd,
    );
    var symptomScore = 30.0; // Default: no symptoms = full points
    if (symptoms.isNotEmpty) {
      final avgSeverity =
          symptoms.fold<double>(0.0, (sum, s) => sum + s.severity) /
          symptoms.length;
      // Invert: low severity = high score
      final severityInverse = 1 - (avgSeverity / 5.0);
      symptomScore = severityInverse * 30;
    }

    return complianceScore + workoutScore + symptomScore;
  }

  /// Generates a date key in format YYYY-MM-DD.
  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  /// Calculates the start of the week (Monday) for a given date.
  DateTime _getWeekStart(DateTime date) {
    // DateTime.weekday returns 1-7 (Monday to Sunday)
    final daysFromMonday = date.weekday - 1;
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: daysFromMonday));
  }
}

// ── Private Data Classes ────────────────────────────────────────────────

class _HealthSummaryData {
  const _HealthSummaryData({
    required this.compliance,
    required this.complianceTrend,
    required this.missedCount,
    required this.problematicTimeSlot,
    required this.symptomCount,
    required this.mostFrequentSymptom,
  });

  final double compliance;
  final TrendDirection complianceTrend;
  final int missedCount;
  final String? problematicTimeSlot;
  final int symptomCount;
  final String? mostFrequentSymptom;
}

class _FitnessSummaryData {
  const _FitnessSummaryData({
    required this.workoutCount,
    required this.totalVolume,
    required this.volumeTrend,
    required this.totalDuration,
    required this.newPRs,
    required this.currentStreak,
  });

  final int workoutCount;
  final double totalVolume;
  final TrendDirection volumeTrend;
  final int totalDuration;
  final List<PersonalRecord> newPRs;
  final int currentStreak;
}

class _CrossModuleData {
  const _CrossModuleData({
    required this.bestDay,
    required this.healthScore,
    required this.topInsights,
  });

  final DateTime? bestDay;
  final double healthScore;
  final List<Insight> topInsights;
}
