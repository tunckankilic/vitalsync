// Tests for the descriptive meal and glucose counts in the weekly report.
//
// The contract is deliberately narrow: the report states how many meals and
// how many readings fell in the week. Nothing averages them, relates them to
// each other or comments on them — see the 2.0 scope boundary.

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vitalsync/core/enums/glucose_source.dart';
import 'package:vitalsync/domain/entities/health/glucose_reading.dart';
import 'package:vitalsync/domain/entities/health/meal.dart';
import 'package:vitalsync/domain/entities/insights/weekly_report.dart';
import 'package:vitalsync/domain/repositories/fitness/personal_record_repository.dart';
import 'package:vitalsync/domain/repositories/fitness/streak_repository.dart';
import 'package:vitalsync/domain/repositories/fitness/workout_session_repository.dart';
import 'package:vitalsync/domain/repositories/health/glucose_repository.dart';
import 'package:vitalsync/domain/repositories/health/health_sample_repository.dart';
import 'package:vitalsync/domain/repositories/health/meal_repository.dart';
import 'package:vitalsync/domain/repositories/health/medication_log_repository.dart';
import 'package:vitalsync/domain/repositories/health/symptom_repository.dart';
import 'package:vitalsync/domain/repositories/insights/insight_repository.dart';
import 'package:vitalsync/features/health/domain/services/meal_data_coverage_service.dart';
import 'package:vitalsync/features/insights/domain/weekly_report_service.dart';

class _MockMedicationLogRepository extends Mock
    implements MedicationLogRepository {}

class _MockWorkoutSessionRepository extends Mock
    implements WorkoutSessionRepository {}

class _MockSymptomRepository extends Mock implements SymptomRepository {}

class _MockInsightRepository extends Mock implements InsightRepository {}

class _MockPersonalRecordRepository extends Mock
    implements PersonalRecordRepository {}

class _MockStreakRepository extends Mock implements StreakRepository {}

class _MockMealRepository extends Mock implements MealRepository {}

class _MockGlucoseRepository extends Mock implements GlucoseRepository {}

class _MockHealthSampleRepository extends Mock
    implements HealthSampleRepository {}

void main() {
  final weekStart = DateTime(2026, 8, 24);

  late _MockMealRepository mealRepository;
  late _MockGlucoseRepository glucoseRepository;
  late _MockHealthSampleRepository healthSampleRepository;
  late WeeklyReportService service;

  Meal meal(int id, DateTime eatenAt) => Meal(
    id: id,
    name: 'meal $id',
    eatenAt: eatenAt,
    tags: const [],
    lastModifiedAt: eatenAt,
    createdAt: eatenAt,
  );

  GlucoseReading reading(int id, DateTime measuredAt) => GlucoseReading(
    id: id,
    valueMgDl: 100,
    measuredAt: measuredAt,
    source: GlucoseSource.manual,
    lastModifiedAt: measuredAt,
    createdAt: measuredAt,
  );

  setUpAll(() {
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    mealRepository = _MockMealRepository();
    glucoseRepository = _MockGlucoseRepository();
    healthSampleRepository = _MockHealthSampleRepository();
    when(
      () => healthSampleRepository.getByDateRange(any(), any()),
    ).thenAnswer((_) async => []);

    final medicationLogRepository = _MockMedicationLogRepository();
    final workoutRepository = _MockWorkoutSessionRepository();
    final symptomRepository = _MockSymptomRepository();
    final insightRepository = _MockInsightRepository();
    final personalRecordRepository = _MockPersonalRecordRepository();
    final streakRepository = _MockStreakRepository();

    // Everything outside the two new counts is empty: this test is only
    // about the meal and glucose figures.
    when(
      () => medicationLogRepository.getByDateRange(any(), any()),
    ).thenAnswer((_) async => []);
    when(
      () => workoutRepository.getByDateRange(any(), any()),
    ).thenAnswer((_) async => []);
    when(
      () => symptomRepository.getByDateRange(any(), any()),
    ).thenAnswer((_) async => []);
    when(
      () => personalRecordRepository.getRecent(limit: any(named: 'limit')),
    ).thenAnswer((_) async => []);
    when(streakRepository.getCurrentStreak).thenAnswer((_) async => 0);
    when(insightRepository.getActive).thenAnswer((_) async => []);

    service = WeeklyReportService(
      medicationLogRepository: medicationLogRepository,
      workoutRepository: workoutRepository,
      symptomRepository: symptomRepository,
      insightRepository: insightRepository,
      personalRecordRepository: personalRecordRepository,
      streakRepository: streakRepository,
      mealRepository: mealRepository,
      glucoseRepository: glucoseRepository,
      coverageService: MealDataCoverageService(
        mealRepository: mealRepository,
        glucoseRepository: glucoseRepository,
        healthSampleRepository: healthSampleRepository,
      ),
    );
  });

  test('reports the number of meals and readings in the week', () async {
    when(() => mealRepository.getByDateRange(any(), any())).thenAnswer(
      (_) async => [
        meal(1, weekStart.add(const Duration(hours: 9))),
        meal(2, weekStart.add(const Duration(days: 2))),
        meal(3, weekStart.add(const Duration(days: 4))),
      ],
    );
    when(() => glucoseRepository.getByDateRange(any(), any())).thenAnswer(
      (_) async => [
        reading(1, weekStart.add(const Duration(hours: 8))),
        reading(2, weekStart.add(const Duration(days: 1))),
      ],
    );

    final report = await service.generateReport(weekStart);

    expect(report.mealsLoggedCount, 3);
    expect(report.glucoseReadingsCount, 2);
  });

  test('reports zero when nothing was recorded', () async {
    when(
      () => mealRepository.getByDateRange(any(), any()),
    ).thenAnswer((_) async => []);
    when(
      () => glucoseRepository.getByDateRange(any(), any()),
    ).thenAnswer((_) async => []);

    final report = await service.generateReport(weekStart);

    expect(report.mealsLoggedCount, 0);
    expect(report.glucoseReadingsCount, 0);
  });

  test('queries both repositories over the reported week', () async {
    when(
      () => mealRepository.getByDateRange(any(), any()),
    ).thenAnswer((_) async => []);
    when(
      () => glucoseRepository.getByDateRange(any(), any()),
    ).thenAnswer((_) async => []);

    await service.generateReport(weekStart);

    final weekEnd = weekStart.add(const Duration(days: 7));
    verify(() => mealRepository.getByDateRange(weekStart, weekEnd)).called(1);
    verify(
      () => glucoseRepository.getByDateRange(weekStart, weekEnd),
    ).called(1);
  });

  test('the counts survive a JSON round trip', () async {
    when(
      () => mealRepository.getByDateRange(any(), any()),
    ).thenAnswer((_) async => [meal(1, weekStart)]);
    when(
      () => glucoseRepository.getByDateRange(any(), any()),
    ).thenAnswer((_) async => [reading(1, weekStart), reading(2, weekStart)]);

    final report = await service.generateReport(weekStart);
    final restored = WeeklyReport.fromJson(report.toJson());

    expect(restored.mealsLoggedCount, 1);
    expect(restored.glucoseReadingsCount, 2);
  });

  test('a report serialized before the counts existed reads as zero', () {
    final json = WeeklyReport.fromJson(
      _reportJsonWithoutCounts(weekStart),
    );

    expect(json.mealsLoggedCount, 0);
    expect(json.glucoseReadingsCount, 0);
  });
}

/// A report payload as it looked before the meal and glucose counts were
/// added — the shape an older GDPR export still carries.
Map<String, dynamic> _reportJsonWithoutCounts(DateTime weekStart) {
  return {
    'start_date': weekStart.toIso8601String(),
    'end_date': weekStart.add(const Duration(days: 7)).toIso8601String(),
    'generated_at': weekStart.toIso8601String(),
    'health_summary': {
      'medication_compliance': 0.0,
      'compliance_trend': 'same',
      'missed_medications_count': 0,
      'most_problematic_time_slot': null,
      'symptoms_logged_count': 0,
      'most_frequent_symptom': null,
    },
    'fitness_summary': {
      'workout_count': 0,
      'total_volume_kg': 0.0,
      'volume_trend': 'same',
      'total_workout_duration_minutes': 0,
      'new_prs': <dynamic>[],
      'current_streak': 0,
    },
    'cross_module_highlights': {
      'best_day': null,
      'health_score': 0.0,
      'top_insights': <dynamic>[],
    },
    'next_week_suggestions': <String>[],
  };
}
