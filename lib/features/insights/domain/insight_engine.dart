/// VitalSync — InsightEngine Core.
///
/// Rule-based insight engine that analyzes cross-module (health + fitness)
/// data to generate personalized recommendations. This is the app's key
/// differentiator. All calculations are pure Dart — no external ML
/// dependencies.
///
/// Each rule method:
/// 1. Fetches required data from repositories
/// 2. Checks minimum sample size (skip if insufficient data)
/// 3. Runs threshold/condition checks
/// 4. Returns an [Insight] if conditions are met, or `null`
///
/// Duplicate prevention: existing active insights of the same rule ID
/// are checked before inserting new ones.
library;

import 'dart:developer' show log;

import 'package:vitalsync/core/enums/insight_category.dart';
import 'package:vitalsync/core/enums/insight_priority.dart';
import 'package:vitalsync/core/enums/insight_type.dart';
import 'package:vitalsync/core/enums/medication_log_status.dart';
import 'package:vitalsync/domain/entities/fitness/workout_set.dart';
import 'package:vitalsync/domain/entities/insights/insight.dart';
import 'package:vitalsync/domain/repositories/fitness/exercise_repository.dart';
import 'package:vitalsync/domain/repositories/fitness/personal_record_repository.dart';
import 'package:vitalsync/domain/repositories/fitness/streak_repository.dart';
import 'package:vitalsync/domain/repositories/fitness/workout_session_repository.dart';
import 'package:vitalsync/domain/repositories/health/medication_log_repository.dart';
import 'package:vitalsync/domain/repositories/health/symptom_repository.dart';
import 'package:vitalsync/domain/repositories/insights/insight_repository.dart';

class InsightEngine {
  InsightEngine({
    required MedicationLogRepository medicationLogRepository,
    required WorkoutSessionRepository workoutRepository,
    required SymptomRepository symptomRepository,
    required InsightRepository insightRepository,
    required PersonalRecordRepository personalRecordRepository,
    required StreakRepository streakRepository,
    required ExerciseRepository exerciseRepository,
  }) : _medicationLogRepository = medicationLogRepository,
       _workoutRepository = workoutRepository,
       _symptomRepository = symptomRepository,
       _insightRepository = insightRepository,
       _personalRecordRepository = personalRecordRepository,
       _streakRepository = streakRepository,
       _exerciseRepository = exerciseRepository;

  final MedicationLogRepository _medicationLogRepository;
  final WorkoutSessionRepository _workoutRepository;
  final SymptomRepository _symptomRepository;
  final InsightRepository _insightRepository;
  final PersonalRecordRepository _personalRecordRepository;
  final StreakRepository _streakRepository;
  final ExerciseRepository _exerciseRepository;

  // ── Rule IDs (used for duplicate prevention) ──────────────────────────

  static const _ruleMedWorkoutCorrelation = 'rule_med_workout_correlation';
  static const _ruleSymptomExercisePattern = 'rule_symptom_exercise_pattern';
  static const _ruleComplianceStreakCorrelation =
      'rule_compliance_streak_correlation';
  static const _ruleComplianceWeekdayPattern =
      'rule_compliance_weekday_pattern';
  static const _ruleSymptomTrend = 'rule_symptom_trend';
  static const _ruleMedAdherenceMilestone = 'rule_med_adherence_milestone';
  static const _ruleVolumePlateau = 'rule_volume_plateau';
  static const _ruleRestDaySuggestion = 'rule_rest_day_suggestion';
  static const _ruleWorkoutConsistency = 'rule_workout_consistency';
  static const _rulePrProximity = 'rule_pr_proximity';

  // ── Public API ────────────────────────────────────────────────────────

  /// Runs all insight rules, inserts new insights, and clears expired ones.
  ///
  /// Returns the list of newly generated insights.
  Future<List<Insight>> generateAllInsights() async {
    try {
      // 1. Fetch existing active insights for duplicate prevention
      final existingInsights = await _insightRepository.getActive();
      final existingRuleIds = <String>{};
      for (final insight in existingInsights) {
        final ruleId = insight.data['ruleId'] as String?;
        if (ruleId != null && insight.validUntil.isAfter(DateTime.now())) {
          existingRuleIds.add(ruleId);
        }
      }

      // 2. Run all rules in parallel-safe order
      final results = <Insight?>[];

      results.add(
        await _safeRun(
          _checkMedicationWorkoutCorrelation,
          _ruleMedWorkoutCorrelation,
          existingRuleIds,
        ),
      );
      // Symptom-exercise can produce multiple insights — handled separately
      final symptomExerciseInsights = await _safeRunMultiple(
        _checkSymptomExercisePattern,
        _ruleSymptomExercisePattern,
        existingRuleIds,
      );
      results.add(
        await _safeRun(
          _checkComplianceStreakCorrelation,
          _ruleComplianceStreakCorrelation,
          existingRuleIds,
        ),
      );
      results.add(
        await _safeRun(
          _checkComplianceWeekdayPattern,
          _ruleComplianceWeekdayPattern,
          existingRuleIds,
        ),
      );
      // Symptom trend can produce multiple insights — one per symptom
      final symptomTrendInsights = await _safeRunMultiple(
        _checkSymptomTrend,
        _ruleSymptomTrend,
        existingRuleIds,
      );
      results.add(
        await _safeRun(
          _checkMedicationAdherenceMilestone,
          _ruleMedAdherenceMilestone,
          existingRuleIds,
        ),
      );
      results.add(
        await _safeRun(
          _checkVolumePlateau,
          _ruleVolumePlateau,
          existingRuleIds,
        ),
      );
      results.add(
        await _safeRun(
          _checkRestDaySuggestion,
          _ruleRestDaySuggestion,
          existingRuleIds,
        ),
      );
      results.add(
        await _safeRun(
          _checkWorkoutConsistencyPattern,
          _ruleWorkoutConsistency,
          existingRuleIds,
        ),
      );
      // PR proximity can produce multiple insights — one per exercise
      final prProximityInsights = await _safeRunMultiple(
        _checkPrProximityAlert,
        _rulePrProximity,
        existingRuleIds,
      );

      // 3. Collect non-null insights
      final newInsights = <Insight>[
        ...results.whereType<Insight>(),
        ...symptomExerciseInsights,
        ...symptomTrendInsights,
        ...prProximityInsights,
      ];

      // 4. Insert into repository
      for (final insight in newInsights) {
        await _insightRepository.insert(insight);
      }

      // 5. Clear expired insights
      await _insightRepository.clearExpired();

      log(
        'InsightEngine: Generated ${newInsights.length} new insights',
        name: 'InsightEngine',
      );

      return newInsights;
    } catch (e, stack) {
      log(
        'InsightEngine: Error generating insights: $e',
        name: 'InsightEngine',
        error: e,
        stackTrace: stack,
      );
      return [];
    }
  }

  // ── CROSS-MODULE INSIGHTS ─────────────────────────────────────────────

  /// Rule 1: Medication-Workout Correlation
  ///
  /// Compares workout volume on days with 100% medication compliance vs
  /// days without. Minimum sample: 10 days in each group.
  Future<Insight?> _checkMedicationWorkoutCorrelation() async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    // Get medication logs and workout sessions for the last 30 days
    final logs = await _medicationLogRepository.getByDateRange(
      thirtyDaysAgo,
      now,
    );
    final sessions = await _workoutRepository.getByDateRange(
      thirtyDaysAgo,
      now,
    );

    if (logs.isEmpty || sessions.isEmpty) return null;

    // Group medication logs by date → determine compliant days
    final logsByDate = <String, List<bool>>{};
    for (final l in logs) {
      final key = _dateKey(l.scheduledTime);
      logsByDate.putIfAbsent(key, () => []);
      logsByDate[key]!.add(l.status == MedicationLogStatus.taken);
    }

    // A day is "compliant" if ALL scheduled medications were taken
    final compliantDays = <String>{};
    final nonCompliantDays = <String>{};
    for (final entry in logsByDate.entries) {
      if (entry.value.every((taken) => taken)) {
        compliantDays.add(entry.key);
      } else {
        nonCompliantDays.add(entry.key);
      }
    }

    // Group workout volume by date
    final volumeByDate = <String, double>{};
    for (final session in sessions) {
      final key = _dateKey(session.startTime);
      volumeByDate[key] = (volumeByDate[key] ?? 0) + session.totalVolume;
    }

    // Calculate average volume for compliant vs non-compliant workout days
    final compliantVolumes = <double>[];
    final nonCompliantVolumes = <double>[];

    for (final entry in volumeByDate.entries) {
      if (compliantDays.contains(entry.key)) {
        compliantVolumes.add(entry.value);
      } else if (nonCompliantDays.contains(entry.key)) {
        nonCompliantVolumes.add(entry.value);
      }
    }

    // Minimum sample size check
    if (compliantVolumes.length < 10 || nonCompliantVolumes.length < 10) {
      return null;
    }

    final avgCompliant = _average(compliantVolumes);
    final avgNonCompliant = _average(nonCompliantVolumes);

    if (avgNonCompliant == 0) return null;

    final percentDiff =
        ((avgCompliant - avgNonCompliant) / avgNonCompliant * 100).round();

    if (percentDiff.abs() < 5) return null; // Too small to be meaningful

    final message = percentDiff > 0
        ? 'Your workout performance is $percentDiff% higher on days when you take all your medications on time.'
        : 'Interesting pattern: your workout volume is slightly different on medication-compliant days.';

    return Insight(
      id: 0, // Auto-assigned by DB
      type: InsightType.correlation,
      category: InsightCategory.crossModule,
      title: 'Medication & Workout Correlation',
      message: message,
      data: {
        'ruleId': _ruleMedWorkoutCorrelation,
        'percentDiff': percentDiff,
        'compliantDayCount': compliantVolumes.length,
        'nonCompliantDayCount': nonCompliantVolumes.length,
        'avgCompliantVolume': avgCompliant.round(),
        'avgNonCompliantVolume': avgNonCompliant.round(),
      },
      priority: InsightPriority.high,
      isRead: false,
      isDismissed: false,
      validUntil: now.add(const Duration(days: 7)),
      generatedAt: now,
    );
  }

  /// Rule 2: Symptom-Exercise Pattern
  ///
  /// For each symptom, checks which exercise categories were performed in
  /// the 24 hours before the symptom was logged. If co-occurrence > 40%
  /// and sample > 5, generates an insight.
  Future<List<Insight>> _checkSymptomExercisePattern() async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final symptoms = await _symptomRepository.getByDateRange(
      thirtyDaysAgo,
      now,
    );
    final sessions = await _workoutRepository.getByDateRange(
      thirtyDaysAgo,
      now,
    );
    final allExercises = await _exerciseRepository.getAll();

    if (symptoms.length < 5 || sessions.isEmpty) return [];

    // Build exercise ID → category name map
    final exerciseCategoryMap = <int, String>{};
    for (final ex in allExercises) {
      exerciseCategoryMap[ex.id] = ex.category.displayName;
    }

    // For each symptom occurrence, find exercise categories in prior 24h
    final symptomCategoryOccurrences = <String, Map<String, int>>{};
    final symptomTotalCount = <String, int>{};

    for (final symptom in symptoms) {
      final name = symptom.name;
      symptomTotalCount[name] = (symptomTotalCount[name] ?? 0) + 1;

      // Find workouts in the 24 hours before this symptom
      final cutoff = symptom.date.subtract(const Duration(hours: 24));
      final priorSessions = sessions.where(
        (s) =>
            s.startTime.isAfter(cutoff) && s.startTime.isBefore(symptom.date),
      );

      // Get exercise categories from those sessions
      for (final session in priorSessions) {
        final sets = await _workoutRepository.getSessionSets(session.id);
        final categories = <String>{};
        for (final set in sets) {
          final cat = exerciseCategoryMap[set.exerciseId];
          if (cat != null) categories.add(cat);
        }
        for (final cat in categories) {
          symptomCategoryOccurrences.putIfAbsent(name, () => {});
          symptomCategoryOccurrences[name]![cat] =
              (symptomCategoryOccurrences[name]![cat] ?? 0) + 1;
        }
      }
    }

    // Check co-occurrence thresholds
    final insights = <Insight>[];
    for (final symptomEntry in symptomCategoryOccurrences.entries) {
      final symptomName = symptomEntry.key;
      final total = symptomTotalCount[symptomName] ?? 0;
      if (total < 5) continue;

      for (final catEntry in symptomEntry.value.entries) {
        final category = catEntry.key;
        final count = catEntry.value;
        final rate = count / total;

        if (rate >= 0.40 && count >= 5) {
          insights.add(
            Insight(
              id: 0,
              type: InsightType.correlation,
              category: InsightCategory.crossModule,
              title: 'Symptom-Exercise Pattern',
              message:
                  'Your $symptomName complaints tend to appear after $category workouts '
                  '(${(rate * 100).round()}% of the time).',
              data: {
                'ruleId': _ruleSymptomExercisePattern,
                'symptom': symptomName,
                'exerciseCategory': category,
                'coOccurrenceRate': rate,
                'sampleSize': total,
              },
              priority: InsightPriority.high,
              isRead: false,
              isDismissed: false,
              validUntil: now.add(const Duration(days: 7)),
              generatedAt: now,
            ),
          );
        }
      }
    }

    return insights;
  }

  /// Rule 3: Compliance-Streak Correlation
  ///
  /// Compares medication compliance streak with workout streak to provide
  /// motivational or course-correcting feedback.
  Future<Insight?> _checkComplianceStreakCorrelation() async {
    final now = DateTime.now();

    final complianceRate = await _medicationLogRepository
        .getOverallComplianceRate(days: 7);
    final workoutStreak = await _streakRepository.getCurrentStreak();

    // Need at least some data
    if (complianceRate < 0 || workoutStreak < 0) return null;

    final highCompliance = complianceRate >= 0.90;
    final highStreak = workoutStreak >= 3;

    String message;
    InsightPriority priority;

    if (highCompliance && highStreak) {
      message =
          'Both your health and fitness routines are going great — '
          '$workoutStreak-day workout streak with '
          '${(complianceRate * 100).round()}% medication compliance!';
      priority = InsightPriority.medium;
    } else if (highCompliance && !highStreak) {
      message =
          'Your medication compliance is excellent at '
          '${(complianceRate * 100).round()}%, but your workout streak could '
          'use a boost. Try a quick session today!';
      priority = InsightPriority.medium;
    } else if (!highCompliance && highStreak) {
      message =
          'Your workouts are on fire with a $workoutStreak-day streak! '
          'Don\'t forget your medications — compliance is at '
          '${(complianceRate * 100).round()}% this week.';
      priority = InsightPriority.high;
    } else {
      // Both low — only show if there's some data
      if (complianceRate == 0 && workoutStreak == 0) return null;
      message =
          'This week has been quiet — let\'s get back on track with both '
          'medications and workouts!';
      priority = InsightPriority.low;
    }

    return Insight(
      id: 0,
      type: InsightType.trend,
      category: InsightCategory.crossModule,
      title: 'Health & Fitness Balance',
      message: message,
      data: {
        'ruleId': _ruleComplianceStreakCorrelation,
        'complianceRate': complianceRate,
        'workoutStreak': workoutStreak,
      },
      priority: priority,
      isRead: false,
      isDismissed: false,
      validUntil: now.add(const Duration(days: 1)),
      generatedAt: now,
    );
  }

  // ── HEALTH INSIGHTS ───────────────────────────────────────────────────

  /// Rule 4: Compliance Weekday Pattern
  ///
  /// Identifies which day(s) of the week have the lowest medication
  /// compliance and suggests adjusting reminders.
  Future<Insight?> _checkComplianceWeekdayPattern() async {
    final now = DateTime.now();

    // Map<int weekday, double complianceRate>
    final weekdayMap = await _medicationLogRepository.getWeekdayComplianceMap(
      days: 30,
    );

    if (weekdayMap.isEmpty) return null;

    // Need at least 7 days of data (all weekdays represented)
    if (weekdayMap.length < 7) return null;

    // Find the worst weekday
    int? worstDay;
    var worstRate = 1.0;
    for (final entry in weekdayMap.entries) {
      if (entry.value < worstRate) {
        worstRate = entry.value;
        worstDay = entry.key;
      }
    }

    if (worstDay == null || worstRate >= 0.80) return null;

    final dayName = _weekdayName(worstDay);
    final percentDrop = ((1.0 - worstRate) * 100).round();

    return Insight(
      id: 0,
      type: InsightType.trend,
      category: InsightCategory.health,
      title: 'Medication Pattern',
      message:
          'Your medication compliance drops by $percentDrop% on ${dayName}s '
          '— would you like to adjust your reminder times?',
      data: {
        'ruleId': _ruleComplianceWeekdayPattern,
        'worstDay': worstDay,
        'worstDayName': dayName,
        'worstRate': worstRate,
        'allRates': weekdayMap,
      },
      priority: InsightPriority.medium,
      isRead: false,
      isDismissed: false,
      validUntil: now.add(const Duration(days: 7)),
      generatedAt: now,
    );
  }

  /// Rule 5: Symptom Trend (severity increase)
  ///
  /// If the average severity of any symptom in the last 7 days is higher
  /// than the prior 7 days, suggests consulting a doctor.
  Future<List<Insight>> _checkSymptomTrend() async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final fourteenDaysAgo = now.subtract(const Duration(days: 14));

    final recentSymptoms = await _symptomRepository.getByDateRange(
      sevenDaysAgo,
      now,
    );
    final priorSymptoms = await _symptomRepository.getByDateRange(
      fourteenDaysAgo,
      sevenDaysAgo,
    );

    if (recentSymptoms.isEmpty || priorSymptoms.isEmpty) return [];

    // Group by symptom name and compute average severity
    final recentAvg = _averageSeverityByName(recentSymptoms);
    final priorAvg = _averageSeverityByName(priorSymptoms);

    final insights = <Insight>[];
    for (final entry in recentAvg.entries) {
      final name = entry.key;
      final recent = entry.value;
      final prior = priorAvg[name];

      // Need both periods and meaningful increase
      if (prior == null) continue;
      if (recent <= prior) continue;
      if (recent - prior < 0.5) continue; // Half-point minimum increase

      insights.add(
        Insight(
          id: 0,
          type: InsightType.anomaly,
          category: InsightCategory.health,
          title: 'Symptom Trend Alert',
          message:
              'Your $name severity has increased from '
              '${prior.toStringAsFixed(1)} to ${recent.toStringAsFixed(1)} '
              'over the past week — you may want to discuss this with your doctor.',
          data: {
            'ruleId': _ruleSymptomTrend,
            'symptom': name,
            'recentAvgSeverity': recent,
            'priorAvgSeverity': prior,
          },
          priority: InsightPriority.critical,
          isRead: false,
          isDismissed: false,
          validUntil: now.add(const Duration(days: 1)),
          generatedAt: now,
        ),
      );
    }

    return insights;
  }

  /// Rule 6: Medication Adherence Milestone
  ///
  /// Celebrates consecutive days of 100% compliance at milestones:
  /// 7, 14, 30, 60, 90 days.
  Future<Insight?> _checkMedicationAdherenceMilestone() async {
    final now = DateTime.now();

    // Check compliance for progressively larger windows
    const milestones = [90, 60, 30, 14, 7];
    for (final days in milestones) {
      final rate = await _medicationLogRepository.getOverallComplianceRate(
        days: days,
      );
      if (rate >= 1.0) {
        return Insight(
          id: 0,
          type: InsightType.milestone,
          category: InsightCategory.health,
          title: 'Medication Milestone 🎉',
          message:
              'You\'ve taken all your medications on time for $days days '
              'straight! Incredible consistency!',
          data: {
            'ruleId': _ruleMedAdherenceMilestone,
            'consecutiveDays': days,
            'complianceRate': rate,
          },
          priority: InsightPriority.high,
          isRead: false,
          isDismissed: false,
          validUntil: now.add(const Duration(days: 30)),
          generatedAt: now,
        );
      }
    }

    return null;
  }

  // ── FITNESS INSIGHTS ──────────────────────────────────────────────────

  /// Rule 7: Volume Plateau Detection
  ///
  /// Compares weekly volume averages over the last 3 weeks. If the
  /// change between weeks is less than 2%, flags a plateau.
  Future<Insight?> _checkVolumePlateau() async {
    final now = DateTime.now();

    // Collect volume for each of the last 3 weeks
    final weekVolumes = <double>[];
    for (var i = 0; i < 3; i++) {
      final weekEnd = now.subtract(Duration(days: 7 * i));
      final weekStart = weekEnd.subtract(const Duration(days: 7));
      final sessions = await _workoutRepository.getByDateRange(
        weekStart,
        weekEnd,
      );
      if (sessions.isEmpty) return null; // Not enough data

      final weekVolume = sessions.fold<double>(
        0.0,
        (sum, s) => sum + s.totalVolume,
      );
      weekVolumes.add(weekVolume);
    }

    if (weekVolumes.length < 3) return null;

    // weekVolumes[0] = this week, [1] = last week, [2] = two weeks ago
    // Check if all three are within 2% of each other
    final avg = _average(weekVolumes);
    if (avg == 0) return null;

    final allWithinThreshold = weekVolumes.every(
      (v) => (v - avg).abs() / avg < 0.02,
    );

    if (!allWithinThreshold) return null;

    return Insight(
      id: 0,
      type: InsightType.trend,
      category: InsightCategory.fitness,
      title: 'Volume Plateau Detected',
      message:
          'Your workout volume has been flat for 3 weeks at ~${avg.round()} kg/week. '
          'Consider a deload week or progressive overload to break through!',
      data: {
        'ruleId': _ruleVolumePlateau,
        'weekVolumes': weekVolumes,
        'averageVolume': avg,
      },
      priority: InsightPriority.medium,
      isRead: false,
      isDismissed: false,
      validUntil: now.add(const Duration(days: 7)),
      generatedAt: now,
    );
  }

  /// Rule 8: Rest Day Suggestion
  ///
  /// If 4+ workouts were completed in the last 5 days, suggests a rest day.
  Future<Insight?> _checkRestDaySuggestion() async {
    final now = DateTime.now();
    final fiveDaysAgo = now.subtract(const Duration(days: 5));

    final workoutDates = await _workoutRepository.getWorkoutDates(days: 5);

    // Count unique workout days in last 5 days
    final recentDays = workoutDates
        .where((d) => d.isAfter(fiveDaysAgo))
        .map(_dateKey)
        .toSet();

    if (recentDays.length < 4) return null;

    return Insight(
      id: 0,
      type: InsightType.suggestion,
      category: InsightCategory.fitness,
      title: 'Rest Day Recommended',
      message:
          'You\'ve worked out ${recentDays.length} out of the last 5 days — '
          'a rest day today could be great for muscle recovery and growth!',
      data: {
        'ruleId': _ruleRestDaySuggestion,
        'workoutDaysInLast5': recentDays.length,
      },
      priority: InsightPriority.medium,
      isRead: false,
      isDismissed: false,
      validUntil: now.add(const Duration(days: 1)),
      generatedAt: now,
    );
  }

  /// Rule 9: Workout Consistency Pattern
  ///
  /// Analyzes which days of the week the user tends to work out,
  /// providing positive reinforcement or pattern awareness.
  Future<Insight?> _checkWorkoutConsistencyPattern() async {
    final now = DateTime.now();
    final workoutDates = await _workoutRepository.getWorkoutDates(days: 30);

    if (workoutDates.length < 4) return null; // Need at least 4 workouts

    // Count workouts per weekday
    final weekdayCounts = <int, int>{};
    for (final date in workoutDates) {
      weekdayCounts[date.weekday] = (weekdayCounts[date.weekday] ?? 0) + 1;
    }

    // Find the top 2 most popular days
    final sorted = weekdayCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sorted.isEmpty) return null;

    final topDays = sorted.take(2).map((e) => _weekdayName(e.key)).toList();
    final topDayStr = topDays.join(' and ');

    return Insight(
      id: 0,
      type: InsightType.trend,
      category: InsightCategory.fitness,
      title: 'Workout Pattern',
      message:
          'You typically work out on $topDayStr — this consistency is great '
          'for building long-term habits!',
      data: {
        'ruleId': _ruleWorkoutConsistency,
        'weekdayCounts': weekdayCounts,
        'totalWorkouts': workoutDates.length,
      },
      priority: InsightPriority.low,
      isRead: false,
      isDismissed: false,
      validUntil: now.add(const Duration(days: 7)),
      generatedAt: now,
    );
  }

  /// Rule 10: PR Proximity Alert
  ///
  /// Checks if the most recent set on any exercise is ≥ 95% of the
  /// personal record for that exercise.
  Future<List<Insight>> _checkPrProximityAlert() async {
    final now = DateTime.now();
    final insights = <Insight>[];

    // Get recent workout sessions (last 3 days)
    final threeDaysAgo = now.subtract(const Duration(days: 3));
    final recentSessions = await _workoutRepository.getByDateRange(
      threeDaysAgo,
      now,
    );

    if (recentSessions.isEmpty) return [];

    // Collect all recent sets
    final recentSets = <WorkoutSet>[];
    for (final session in recentSessions) {
      final sets = await _workoutRepository.getSessionSets(session.id);
      recentSets.addAll(sets.where((s) => !s.isWarmup));
    }

    if (recentSets.isEmpty) return [];

    // Group by exercise, find the best recent set per exercise
    final bestByExercise = <int, WorkoutSet>{};
    for (final set in recentSets) {
      final current = bestByExercise[set.exerciseId];
      if (current == null ||
          _estimatedVolume(set) > _estimatedVolume(current)) {
        bestByExercise[set.exerciseId] = set;
      }
    }

    // Compare each best set against its PR
    final allExercises = await _exerciseRepository.getAll();
    final exerciseNameMap = <int, String>{};
    for (final ex in allExercises) {
      exerciseNameMap[ex.id] = ex.name;
    }

    for (final entry in bestByExercise.entries) {
      final exerciseId = entry.key;
      final bestSet = entry.value;

      final pr = await _personalRecordRepository.getForExercise(exerciseId);
      if (pr == null) continue;

      // Compare weight × reps (simplified) — skip if already a PR
      if (bestSet.isPR) continue;

      final prVolume = pr.weight * pr.reps;
      final setVolume = bestSet.weight * bestSet.reps;

      if (prVolume == 0) continue;

      final ratio = setVolume / prVolume;

      if (ratio >= 0.95 && ratio < 1.0) {
        final exerciseName = exerciseNameMap[exerciseId] ?? 'Unknown';
        insights.add(
          Insight(
            id: 0,
            type: InsightType.suggestion,
            category: InsightCategory.fitness,
            title: 'PR Proximity Alert 🔥',
            message:
                'You\'re very close to your $exerciseName PR! Your recent set '
                'was ${bestSet.weight}kg × ${bestSet.reps} — '
                'PR is ${pr.weight}kg × ${pr.reps}.',
            data: {
              'ruleId': _rulePrProximity,
              'exerciseId': exerciseId,
              'exerciseName': exerciseName,
              'recentWeight': bestSet.weight,
              'recentReps': bestSet.reps,
              'prWeight': pr.weight,
              'prReps': pr.reps,
              'ratio': ratio,
            },
            priority: InsightPriority.high,
            isRead: false,
            isDismissed: false,
            validUntil: now.add(const Duration(days: 3)),
            generatedAt: now,
          ),
        );
      }
    }

    return insights;
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  /// Run a single-insight rule with error handling and duplicate check.
  Future<Insight?> _safeRun(
    Future<Insight?> Function() rule,
    String ruleId,
    Set<String> existingRuleIds,
  ) async {
    if (existingRuleIds.contains(ruleId)) return null;
    try {
      return await rule();
    } catch (e, stack) {
      log(
        'InsightEngine: Rule $ruleId failed: $e',
        name: 'InsightEngine',
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }

  /// Run a multi-insight rule with error handling and duplicate check.
  Future<List<Insight>> _safeRunMultiple(
    Future<List<Insight>> Function() rule,
    String ruleId,
    Set<String> existingRuleIds,
  ) async {
    if (existingRuleIds.contains(ruleId)) return [];
    try {
      return await rule();
    } catch (e, stack) {
      log(
        'InsightEngine: Rule $ruleId failed: $e',
        name: 'InsightEngine',
        error: e,
        stackTrace: stack,
      );
      return [];
    }
  }

  /// Date key for grouping: yyyy-MM-dd
  String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  /// Average of a list of doubles.
  double _average(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// Weekday number to name.
  String _weekdayName(int weekday) {
    const names = {
      1: 'Monday',
      2: 'Tuesday',
      3: 'Wednesday',
      4: 'Thursday',
      5: 'Friday',
      6: 'Saturday',
      7: 'Sunday',
    };
    return names[weekday] ?? 'Unknown';
  }

  /// Average severity grouped by symptom name.
  Map<String, double> _averageSeverityByName(List<dynamic> symptoms) {
    final sums = <String, double>{};
    final counts = <String, int>{};
    for (final s in symptoms) {
      final name = s.name as String;
      final severity = (s.severity as int).toDouble();
      sums[name] = (sums[name] ?? 0) + severity;
      counts[name] = (counts[name] ?? 0) + 1;
    }
    return {
      for (final entry in sums.entries)
        entry.key: entry.value / counts[entry.key]!,
    };
  }

  /// Estimated volume for a single set (weight × reps).
  double _estimatedVolume(WorkoutSet set) => set.weight * set.reps;
}
