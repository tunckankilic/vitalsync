// Pins the weekly report figures the UI reads.
//
// Every one of these used to render as 0: the screen, both share cards and
// the dashboard read flat keys off `toJson()`, whose shape is the nested
// GDPR export. The UI is typed now, and these tests hold the service to
// producing the values it hands over.

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vitalsync/core/enums/equipment.dart';
import 'package:vitalsync/core/enums/exercise_category.dart';
import 'package:vitalsync/core/enums/medication_log_status.dart';
import 'package:vitalsync/domain/entities/fitness/exercise.dart';
import 'package:vitalsync/domain/entities/fitness/personal_record.dart';
import 'package:vitalsync/domain/entities/fitness/workout_session.dart';
import 'package:vitalsync/domain/entities/health/medication_log.dart';
import 'package:vitalsync/domain/entities/health/symptom.dart';
import 'package:vitalsync/domain/entities/insights/weekly_report.dart';
import 'package:vitalsync/domain/repositories/fitness/exercise_repository.dart';
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

class _MockExerciseRepository extends Mock implements ExerciseRepository {}

void main() {
  // Monday 2026-08-24. The previous week starts Monday 2026-08-17.
  final weekStart = DateTime(2026, 8, 24);
  final previousWeekStart = weekStart.subtract(const Duration(days: 7));

  late _MockMedicationLogRepository medicationLogRepository;
  late _MockWorkoutSessionRepository workoutRepository;
  late _MockSymptomRepository symptomRepository;
  late _MockPersonalRecordRepository personalRecordRepository;
  late _MockExerciseRepository exerciseRepository;
  late WeeklyReportService service;

  MedicationLog logAt(int id, DateTime at, MedicationLogStatus status) =>
      MedicationLog(
        id: id,
        medicationId: 1,
        scheduledTime: at,
        status: status,
        lastModifiedAt: at,
        createdAt: at,
      );

  WorkoutSession sessionOn(int id, DateTime startTime, double volume) =>
      WorkoutSession(
        id: id,
        name: 'Session $id',
        startTime: startTime,
        endTime: startTime.add(const Duration(minutes: 60)),
        totalVolume: volume,
        lastModifiedAt: startTime,
        createdAt: startTime,
      );

  Symptom symptomOn(int id, DateTime date) => Symptom(
    id: id,
    name: 'ache',
    severity: 2,
    date: date,
    tags: const [],
    lastModifiedAt: date,
    createdAt: date,
  );

  setUpAll(() {
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    medicationLogRepository = _MockMedicationLogRepository();
    workoutRepository = _MockWorkoutSessionRepository();
    symptomRepository = _MockSymptomRepository();
    personalRecordRepository = _MockPersonalRecordRepository();
    exerciseRepository = _MockExerciseRepository();

    final mealRepository = _MockMealRepository();
    final glucoseRepository = _MockGlucoseRepository();
    final healthSampleRepository = _MockHealthSampleRepository();
    final insightRepository = _MockInsightRepository();
    final streakRepository = _MockStreakRepository();

    // Empty by default; each test fills in only what it is about.
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
      () => mealRepository.getByDateRange(any(), any()),
    ).thenAnswer((_) async => []);
    when(
      () => glucoseRepository.getByDateRange(any(), any()),
    ).thenAnswer((_) async => []);
    when(
      () => healthSampleRepository.getByDateRange(any(), any()),
    ).thenAnswer((_) async => []);
    when(
      () => personalRecordRepository.getRecent(limit: any(named: 'limit')),
    ).thenAnswer((_) async => []);
    when(() => exerciseRepository.getByIds(any())).thenAnswer((_) async => []);
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
      exerciseRepository: exerciseRepository,
    );
  });

  group('dose outcomes', () {
    setUp(() {
      when(
        () => medicationLogRepository.getByDateRange(weekStart, any()),
      ).thenAnswer(
        (_) async => [
          logAt(1, weekStart, MedicationLogStatus.taken),
          logAt(2, weekStart, MedicationLogStatus.taken),
          logAt(3, weekStart, MedicationLogStatus.missed),
          logAt(4, weekStart, MedicationLogStatus.skipped),
        ],
      );
    });

    test('taken, missed and skipped are counted separately', () async {
      final report = await service.generateReport(weekStart);

      expect(report.takenMedicationsCount, 2);
      // Strictly missed — the skipped dose is not folded in here.
      expect(report.missedMedicationsCount, 1);
      expect(report.skippedMedicationsCount, 1);
    });

    test('the three counts feed a donut that adds up to the logs', () async {
      final report = await service.generateReport(weekStart);

      final total =
          report.takenMedicationsCount +
          report.missedMedicationsCount +
          report.skippedMedicationsCount;
      expect(total, 4);
    });
  });

  test('previous-week compliance and symptom count travel on the report',
      () async {
    when(
      () => medicationLogRepository.getByDateRange(weekStart, any()),
    ).thenAnswer(
      (_) async => [logAt(1, weekStart, MedicationLogStatus.taken)],
    );
    when(
      () => medicationLogRepository.getByDateRange(
        previousWeekStart,
        weekStart,
      ),
    ).thenAnswer(
      (_) async => [
        logAt(2, previousWeekStart, MedicationLogStatus.taken),
        logAt(3, previousWeekStart, MedicationLogStatus.missed),
      ],
    );
    when(
      () => symptomRepository.getByDateRange(previousWeekStart, weekStart),
    ).thenAnswer((_) async => [symptomOn(1, previousWeekStart)]);

    final report = await service.generateReport(weekStart);

    expect(report.medicationCompliance, 1.0);
    expect(report.previousMedicationCompliance, 0.5);
    expect(report.previousSymptomsLoggedCount, 1);
  });

  group('daily volumes', () {
    test('volume is bucketed per weekday, Monday first', () async {
      when(
        () => workoutRepository.getByDateRange(weekStart, any()),
      ).thenAnswer(
        (_) async => [
          sessionOn(1, weekStart.add(const Duration(hours: 9)), 100),
          // Same day, second session — volumes add up.
          sessionOn(2, weekStart.add(const Duration(hours: 18)), 50),
          // Wednesday.
          sessionOn(3, weekStart.add(const Duration(days: 2)), 200),
        ],
      );

      final report = await service.generateReport(weekStart);

      expect(report.dailyVolumes, [150, 0, 200, 0, 0, 0, 0]);
      expect(report.dailyVolumes, hasLength(7));
    });

    test('the previous week gets its own series for the ghost bars', () async {
      when(
        () => workoutRepository.getByDateRange(previousWeekStart, weekStart),
      ).thenAnswer(
        (_) async => [
          sessionOn(1, previousWeekStart.add(const Duration(days: 1)), 300),
        ],
      );

      final report = await service.generateReport(weekStart);

      expect(report.previousDailyVolumes, [0, 300, 0, 0, 0, 0, 0]);
      expect(report.previousWorkoutCount, 1);
    });

    test('a week with no sessions still yields seven zeroes', () async {
      final report = await service.generateReport(weekStart);

      expect(report.dailyVolumes, [0, 0, 0, 0, 0, 0, 0]);
    });
  });

  group('best workout', () {
    test('is the heaviest session of the week', () async {
      when(
        () => workoutRepository.getByDateRange(weekStart, any()),
      ).thenAnswer(
        (_) async => [
          sessionOn(1, weekStart, 100),
          sessionOn(2, weekStart.add(const Duration(days: 1)), 450),
          sessionOn(3, weekStart.add(const Duration(days: 2)), 200),
        ],
      );

      final report = await service.generateReport(weekStart);

      expect(report.bestWorkoutName, 'Session 2');
      expect(report.bestWorkoutVolume, 450);
    });

    test('is null when the week had no sessions', () async {
      final report = await service.generateReport(weekStart);

      expect(report.bestWorkoutName, isNull);
      expect(report.bestWorkoutVolume, isNull);
    });
  });

  group('PR exercise names', () {
    setUp(() {
      when(
        () => personalRecordRepository.getRecent(limit: any(named: 'limit')),
      ).thenAnswer(
        (_) async => [
          PersonalRecord(
            id: 1,
            exerciseId: 7,
            weight: 100,
            reps: 5,
            estimated1RM: 112.5,
            achievedAt: weekStart.add(const Duration(days: 1)),
          ),
        ],
      );
      when(() => exerciseRepository.getByIds([7])).thenAnswer(
        (_) async => [
          Exercise(
            id: 7,
            name: 'Bench Press',
            category: ExerciseCategory.values.first,
            muscleGroup: 'chest',
            equipment: Equipment.values.first,
            isCustom: false,
            createdAt: weekStart,
          ),
        ],
      );
    });

    test('are resolved so the report renders without database access',
        () async {
      final report = await service.generateReport(weekStart);

      expect(report.newPRs, hasLength(1));
      expect(report.exerciseNames[7], 'Bench Press');
    });

    test('are looked up in one batched call, not one query per PR', () async {
      await service.generateReport(weekStart);

      verify(() => exerciseRepository.getByIds([7])).called(1);
    });

    test('survive the export round trip', () async {
      final report = await service.generateReport(weekStart);
      final restored = WeeklyReport.fromJson(report.toJson());

      expect(restored.exerciseNames[7], 'Bench Press');
    });
  });

  test('every new figure survives the export round trip', () async {
    when(
      () => medicationLogRepository.getByDateRange(weekStart, any()),
    ).thenAnswer(
      (_) async => [
        logAt(1, weekStart, MedicationLogStatus.taken),
        logAt(2, weekStart, MedicationLogStatus.skipped),
      ],
    );
    when(() => workoutRepository.getByDateRange(weekStart, any())).thenAnswer(
      (_) async => [sessionOn(1, weekStart, 120)],
    );

    final report = await service.generateReport(weekStart);
    final restored = WeeklyReport.fromJson(report.toJson());

    expect(restored.takenMedicationsCount, report.takenMedicationsCount);
    expect(restored.skippedMedicationsCount, report.skippedMedicationsCount);
    expect(
      restored.previousMedicationCompliance,
      report.previousMedicationCompliance,
    );
    expect(
      restored.previousSymptomsLoggedCount,
      report.previousSymptomsLoggedCount,
    );
    expect(restored.dailyVolumes, report.dailyVolumes);
    expect(restored.previousDailyVolumes, report.previousDailyVolumes);
    expect(restored.previousWorkoutCount, report.previousWorkoutCount);
    expect(restored.bestWorkoutName, report.bestWorkoutName);
    expect(restored.bestWorkoutVolume, report.bestWorkoutVolume);
  });

  test('a report exported before these fields existed reads as empty', () {
    final report = WeeklyReport.fromJson({
      'start_date': weekStart.toIso8601String(),
      'end_date': weekStart.add(const Duration(days: 7)).toIso8601String(),
      'generated_at': weekStart.toIso8601String(),
      'health_summary': {
        'medication_compliance': 0.5,
        'compliance_trend': 'same',
        'missed_medications_count': 1,
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
    });

    expect(report.takenMedicationsCount, 0);
    expect(report.skippedMedicationsCount, 0);
    expect(report.previousMedicationCompliance, 0);
    expect(report.dailyVolumes, isEmpty);
    expect(report.bestWorkoutName, isNull);
    expect(report.exerciseNames, isEmpty);
  });
}
