import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vitalsync/core/enums/insight_category.dart';
import 'package:vitalsync/core/enums/insight_priority.dart';
import 'package:vitalsync/core/enums/insight_type.dart';
import 'package:vitalsync/core/enums/medication_log_status.dart';
import 'package:vitalsync/domain/entities/fitness/workout_session.dart';
import 'package:vitalsync/domain/entities/health/medication_log.dart';
import 'package:vitalsync/domain/entities/health/symptom.dart';
import 'package:vitalsync/domain/entities/insights/insight.dart';
import 'package:vitalsync/domain/repositories/fitness/exercise_repository.dart';
import 'package:vitalsync/domain/repositories/fitness/personal_record_repository.dart';
import 'package:vitalsync/domain/repositories/fitness/streak_repository.dart';
import 'package:vitalsync/domain/repositories/fitness/workout_session_repository.dart';
import 'package:vitalsync/domain/repositories/health/medication_log_repository.dart';
import 'package:vitalsync/domain/repositories/health/symptom_repository.dart';
import 'package:vitalsync/domain/repositories/insights/insight_repository.dart';
import 'package:vitalsync/features/insights/domain/insight_engine.dart';

// ── Mocks ────────────────────────────────────────────────────────────────────

class MockMedicationLogRepository extends Mock
    implements MedicationLogRepository {}

class MockWorkoutSessionRepository extends Mock
    implements WorkoutSessionRepository {}

class MockSymptomRepository extends Mock implements SymptomRepository {}

class MockInsightRepository extends Mock implements InsightRepository {}

class MockPersonalRecordRepository extends Mock
    implements PersonalRecordRepository {}

class MockStreakRepository extends Mock implements StreakRepository {}

class MockExerciseRepository extends Mock implements ExerciseRepository {}

void main() {
  late InsightEngine engine;
  late MockMedicationLogRepository mockMedLogRepo;
  late MockWorkoutSessionRepository mockWorkoutRepo;
  late MockSymptomRepository mockSymptomRepo;
  late MockInsightRepository mockInsightRepo;
  late MockPersonalRecordRepository mockPRRepo;
  late MockStreakRepository mockStreakRepo;
  late MockExerciseRepository mockExerciseRepo;

  setUp(() {
    mockMedLogRepo = MockMedicationLogRepository();
    mockWorkoutRepo = MockWorkoutSessionRepository();
    mockSymptomRepo = MockSymptomRepository();
    mockInsightRepo = MockInsightRepository();
    mockPRRepo = MockPersonalRecordRepository();
    mockStreakRepo = MockStreakRepository();
    mockExerciseRepo = MockExerciseRepository();

    engine = InsightEngine(
      medicationLogRepository: mockMedLogRepo,
      workoutRepository: mockWorkoutRepo,
      symptomRepository: mockSymptomRepo,
      insightRepository: mockInsightRepo,
      personalRecordRepository: mockPRRepo,
      streakRepository: mockStreakRepo,
      exerciseRepository: mockExerciseRepo,
    );

    // Register fallback values for mocktail argument matchers
    registerFallbackValue(
      Insight(
        id: 0,
        type: InsightType.suggestion,
        category: InsightCategory.crossModule,
        title: '',
        message: '',
        data: const {},
        priority: InsightPriority.low,
        isRead: false,
        isDismissed: false,
        validUntil: DateTime.now(),
        generatedAt: DateTime.now(),
      ),
    );
  });

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Stubs all repositories to return empty / zero data so every rule
  /// short-circuits with no insight generated.
  void stubEmptyRepositories() {
    when(() => mockInsightRepo.getActive()).thenAnswer((_) async => []);
    when(() => mockInsightRepo.clearExpired()).thenAnswer((_) async {});
    when(() => mockInsightRepo.insert(any())).thenAnswer((_) async {});

    // Rule 1 — med-workout correlation
    when(
      () => mockMedLogRepo.getByDateRange(any(), any()),
    ).thenAnswer((_) async => []);
    when(
      () => mockWorkoutRepo.getByDateRange(any(), any()),
    ).thenAnswer((_) async => []);

    // Rule 2 — symptom-exercise pattern
    when(
      () => mockSymptomRepo.getByDateRange(any(), any()),
    ).thenAnswer((_) async => []);
    when(() => mockExerciseRepo.getAll()).thenAnswer((_) async => []);

    // Rule 3 — compliance-streak
    when(
      () => mockMedLogRepo.getOverallComplianceRate(days: any(named: 'days')),
    ).thenAnswer((_) async => 0.0);
    when(() => mockStreakRepo.getCurrentStreak()).thenAnswer((_) async => 0);

    // Rule 4 — compliance weekday
    when(
      () => mockMedLogRepo.getWeekdayComplianceMap(days: any(named: 'days')),
    ).thenAnswer((_) async => {});

    // Rule 6 — med adherence milestone (covered by getOverallComplianceRate)

    // Rule 7 — volume plateau (covered by getByDateRange)

    // Rule 8 — rest day
    when(
      () => mockWorkoutRepo.getWorkoutDates(days: any(named: 'days')),
    ).thenAnswer((_) async => []);

    // Rule 10 — PR proximity
    when(() => mockPRRepo.getForExercise(any())).thenAnswer((_) async => null);
  }

  // ── Test Groups ────────────────────────────────────────────────────────

  group('InsightEngine.generateAllInsights', () {
    test('returns empty list when all repositories return no data', () async {
      // Arrange
      stubEmptyRepositories();

      // Act
      final insights = await engine.generateAllInsights();

      // Assert
      expect(insights, isEmpty);
      verify(() => mockInsightRepo.getActive()).called(1);
      verify(() => mockInsightRepo.clearExpired()).called(1);
    });
  });

  group('Rule 1 — Medication-Workout Correlation', () {
    test(
      'generates insight when compliant days have higher workout volume',
      () async {
        // Arrange
        stubEmptyRepositories();

        final now = DateTime.now();

        // Build 20+ medication logs: 12 compliant days, 12 non-compliant days
        final medLogs = <MedicationLog>[];
        final sessions = <WorkoutSession>[];

        for (var i = 0; i < 24; i++) {
          final day = now.subtract(Duration(days: i));
          final isCompliant = i < 12; // first 12 days compliant

          medLogs.add(
            MedicationLog(
              id: i,
              medicationId: 1,
              scheduledTime: day,
              status: isCompliant
                  ? MedicationLogStatus.taken
                  : MedicationLogStatus.missed,
              lastModifiedAt: day,
              createdAt: day,
            ),
          );

          // Compliant days: volume 200, non-compliant days: volume 100
          sessions.add(
            WorkoutSession(
              id: i,
              name: 'Session $i',
              startTime: day,
              totalVolume: isCompliant ? 200.0 : 100.0,
              lastModifiedAt: day,
              createdAt: day,
            ),
          );
        }

        when(
          () => mockMedLogRepo.getByDateRange(any(), any()),
        ).thenAnswer((_) async => medLogs);
        when(
          () => mockWorkoutRepo.getByDateRange(any(), any()),
        ).thenAnswer((_) async => sessions);

        // Act
        final insights = await engine.generateAllInsights();

        // Assert — at least one insight should be the med-workout correlation
        final correlationInsights = insights.where(
          (i) => i.data['ruleId'] == 'rule_med_workout_correlation',
        );
        expect(correlationInsights, isNotEmpty);

        final insight = correlationInsights.first;
        expect(insight.data['percentDiff'], isPositive);
        expect(insight.category, InsightCategory.crossModule);
      },
    );
  });

  group('Rule 5 — Symptom Trend', () {
    test(
      'detects severity increase between prior and recent weeks',
      () async {
        // Arrange
        stubEmptyRepositories();

        final now = DateTime.now();

        // Recent week: severity 8
        final recentSymptoms = List.generate(
          5,
          (i) => Symptom(
            id: i,
            name: 'Headache',
            severity: 8,
            date: now.subtract(Duration(days: i)),
            tags: const [],
            lastModifiedAt: now,
            createdAt: now,
          ),
        );

        // Prior week: severity 3
        final priorSymptoms = List.generate(
          5,
          (i) => Symptom(
            id: 100 + i,
            name: 'Headache',
            severity: 3,
            date: now.subtract(Duration(days: 7 + i)),
            tags: const [],
            lastModifiedAt: now,
            createdAt: now,
          ),
        );

        // The engine calls getByDateRange with different windows:
        //   - rule 2 (symptom-exercise): 30 days ago → now
        //   - rule 5 (symptom trend) recent: 7 days ago → now
        //   - rule 5 (symptom trend) prior:  14 days ago → 7 days ago
        // Match on the start-date argument rather than call order, so the
        // stub stays correct regardless of how many rules call this or in
        // what sequence.
        when(
          () => mockSymptomRepo.getByDateRange(any(), any()),
        ).thenAnswer((invocation) async {
          final start = invocation.positionalArguments[0] as DateTime;
          final daysAgo = now.difference(start).inDays;
          if (daysAgo <= 8) return recentSymptoms; // recent week (~7d)
          if (daysAgo <= 15) return priorSymptoms; // prior week (~14d)
          return []; // wider windows (e.g. rule 2's 30d) — no data
        });

        // Act
        final insights = await engine.generateAllInsights();

        // Assert
        final trendInsights = insights.where(
          (i) => i.data['ruleId'] == 'rule_symptom_trend',
        );
        expect(trendInsights, isNotEmpty);

        final trend = trendInsights.first;
        expect(trend.data['symptom'], 'Headache');
        expect(
          trend.data['recentAvgSeverity'] as double,
          greaterThan(trend.data['priorAvgSeverity'] as double),
        );
        expect(trend.priority, InsightPriority.critical);
      },
    );
  });

  group('Duplicate prevention', () {
    test('skips rule when its ruleId already exists in active insights',
        () async {
      // Arrange
      stubEmptyRepositories();

      final now = DateTime.now();

      // Return an existing active insight with the med-workout correlation
      // rule ID so that rule is skipped.
      when(() => mockInsightRepo.getActive()).thenAnswer(
        (_) async => [
          Insight(
            id: 99,
            type: InsightType.correlation,
            category: InsightCategory.crossModule,
            title: 'Existing',
            message: 'Already generated',
            data: const {'ruleId': 'rule_med_workout_correlation'},
            priority: InsightPriority.high,
            isRead: false,
            isDismissed: false,
            validUntil: now.add(const Duration(days: 7)),
            generatedAt: now,
          ),
        ],
      );

      // Even though med logs and sessions have enough data, the rule should
      // be skipped entirely because the ruleId exists.
      final medLogs = <MedicationLog>[];
      final sessions = <WorkoutSession>[];
      for (var i = 0; i < 24; i++) {
        final day = now.subtract(Duration(days: i));
        final isCompliant = i < 12;
        medLogs.add(
          MedicationLog(
            id: i,
            medicationId: 1,
            scheduledTime: day,
            status: isCompliant
                ? MedicationLogStatus.taken
                : MedicationLogStatus.missed,
            lastModifiedAt: day,
            createdAt: day,
          ),
        );
        sessions.add(
          WorkoutSession(
            id: i,
            name: 'Session $i',
            startTime: day,
            totalVolume: isCompliant ? 200.0 : 100.0,
            lastModifiedAt: day,
            createdAt: day,
          ),
        );
      }

      when(
        () => mockMedLogRepo.getByDateRange(any(), any()),
      ).thenAnswer((_) async => medLogs);
      when(
        () => mockWorkoutRepo.getByDateRange(any(), any()),
      ).thenAnswer((_) async => sessions);

      // Act
      final insights = await engine.generateAllInsights();

      // Assert — no med-workout correlation insight should be generated
      final correlationInsights = insights.where(
        (i) => i.data['ruleId'] == 'rule_med_workout_correlation',
      );
      expect(correlationInsights, isEmpty);
    });
  });
}
