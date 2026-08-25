// Guards the `==` / `hashCode` contract on the entities that carry a
// collection field.
//
// All of these compare their List/Map field element-wise in `operator ==`
// but used to hash it with `List.hashCode` / `Map.hashCode`, which are
// identity-based. Two equal instances therefore landed in different hash
// buckets: `Set` deduplication, `Map` lookup and `contains` all silently
// misbehaved.
//
// The rule under test is Dart's: `a == b` implies `a.hashCode == b.hashCode`.

import 'package:flutter_test/flutter_test.dart';
import 'package:vitalsync/core/enums/insight_category.dart';
import 'package:vitalsync/core/enums/insight_priority.dart';
import 'package:vitalsync/core/enums/insight_type.dart';
import 'package:vitalsync/core/enums/medication_frequency.dart';
import 'package:vitalsync/core/enums/trend_direction.dart';
import 'package:vitalsync/domain/entities/fitness/personal_record.dart';
import 'package:vitalsync/domain/entities/fitness/template_exercise.dart';
import 'package:vitalsync/domain/entities/fitness/workout_template.dart';
import 'package:vitalsync/domain/entities/health/meal.dart';
import 'package:vitalsync/domain/entities/health/medication.dart';
import 'package:vitalsync/domain/entities/health/symptom.dart';
import 'package:vitalsync/domain/entities/insights/insight.dart';
import 'package:vitalsync/domain/entities/insights/weekly_report.dart';
import 'package:vitalsync/domain/entities/shared/calibration_metric.dart';
import 'package:vitalsync/features/health/domain/services/meal_data_coverage_service.dart'
    show UncoveredReason;

void main() {
  final at = DateTime(2026, 8, 25, 12);

  /// Asserts the full contract on two instances built to be equal but held
  /// in separate collection objects.
  void expectEqualAndHashAlike<T>(T a, T b) {
    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
    // The practical consequence: a Set must collapse them into one.
    expect({a, b}, hasLength(1));
  }

  group('meal', () {
    Meal build() => Meal(
          id: 1,
          name: 'Lunch',
          eatenAt: at,
          // A fresh list each call: same contents, different identity.
          tags: ['home', 'quick'],
          lastModifiedAt: at,
          createdAt: at,
        );

    test('equal meals hash alike despite separate tag lists', () {
      expectEqualAndHashAlike(build(), build());
    });

    test('different tags are still unequal', () {
      final other = build().copyWith(tags: const ['out']);
      expect(build(), isNot(equals(other)));
    });
  });

  group('symptom', () {
    Symptom build() => Symptom(
          id: 1,
          name: 'Headache',
          severity: 3,
          date: at,
          tags: ['morning'],
          lastModifiedAt: at,
          createdAt: at,
        );

    test('equal symptoms hash alike despite separate tag lists', () {
      expectEqualAndHashAlike(build(), build());
    });
  });

  group('medication', () {
    Medication build() => Medication(
          id: 1,
          name: 'Aspirin',
          dosage: '100mg',
          frequency: MedicationFrequency.twiceDaily,
          times: ['08:00', '20:00'],
          startDate: at,
          color: 0xFF000000,
          isActive: true,
          lastModifiedAt: at,
          createdAt: at,
          updatedAt: at,
        );

    test('equal medications hash alike despite separate time lists', () {
      expectEqualAndHashAlike(build(), build());
    });

    test('a different dose time makes them unequal', () {
      final other = build().copyWith(times: const ['08:00', '21:00']);
      expect(build(), isNot(equals(other)));
    });
  });

  group('calibration metric', () {
    CalibrationMetric build({bool reverseOrder = false}) {
      final entries = <MapEntry<String, int>>[
        MapEntry(UncoveredReason.noReadings.name, 2),
        MapEntry(UncoveredReason.gapInData.name, 1),
      ];
      return CalibrationMetric(
        id: 1,
        weekStart: at,
        mealsLogged: 5,
        glucoseReadings: 12,
        manualReadings: 4,
        coveredMeals: 2,
        uncoveredReasons: Map.fromEntries(
          reverseOrder ? entries.reversed : entries,
        ),
        appVersion: '1.0.0',
        lastModifiedAt: at,
        createdAt: at,
      );
    }

    test('equal metrics hash alike despite separate reason maps', () {
      expectEqualAndHashAlike(build(), build());
    });

    test('insertion order of the reason map does not change the hash', () {
      expectEqualAndHashAlike(build(), build(reverseOrder: true));
    });

    test('different reason counts are still unequal', () {
      final other = build().copyWith(
        uncoveredReasons: {UncoveredReason.noReadings.name: 99},
      );
      expect(build(), isNot(equals(other)));
    });
  });

  group('insight', () {
    Insight build() => Insight(
          id: 1,
          type: InsightType.values.first,
          category: InsightCategory.values.first,
          title: 'Title',
          message: 'Message',
          data: {'count': 3, 'label': 'x'},
          priority: InsightPriority.high,
          isRead: false,
          isDismissed: false,
          validUntil: at.add(const Duration(days: 7)),
          generatedAt: at,
        );

    test('equal insights hash alike despite separate data maps', () {
      expectEqualAndHashAlike(build(), build());
    });
  });

  group('workout template', () {
    TemplateExercise exercise() => const TemplateExercise(
          id: 1,
          templateId: 1,
          exerciseId: 1,
          orderIndex: 0,
          defaultSets: 3,
          defaultReps: 10,
          restSeconds: 90,
        );

    WorkoutTemplate build() => WorkoutTemplate(
          id: 1,
          name: 'Push Day',
          color: 0xFF000000,
          estimatedDuration: 60,
          isDefault: false,
          exercises: [exercise()],
          createdAt: at,
          updatedAt: at,
        );

    test('equal templates hash alike despite separate exercise lists', () {
      expectEqualAndHashAlike(build(), build());
    });
  });

  group('weekly report', () {
    WeeklyReport build({String suggestion = 'Keep logging'}) => WeeklyReport(
          startDate: at,
          endDate: at.add(const Duration(days: 7)),
          generatedAt: at,
          medicationCompliance: 0.8,
          complianceTrendVsPrevious: TrendDirection.up,
          missedMedicationsCount: 1,
          symptomsLoggedCount: 2,
          workoutCount: 3,
          totalVolume: 1000,
          volumeTrendVsPrevious: TrendDirection.same,
          totalWorkoutDuration: 180,
          newPRs: [
            PersonalRecord(
              id: 1,
              exerciseId: 1,
              weight: 100,
              reps: 5,
              estimated1RM: 112.5,
              achievedAt: at,
            ),
          ],
          currentStreak: 4,
          healthScore: 72,
          topInsights: const [],
          suggestions: [suggestion],
        );

    test('equal reports hash alike despite separate lists', () {
      expectEqualAndHashAlike(build(), build());
    });

    // The list fields used to be compared by length alone, so two reports
    // with entirely different contents came out equal.
    test('same-length but different suggestions are unequal', () {
      expect(build(), isNot(equals(build(suggestion: 'Something else'))));
    });

    test('same-length but different PRs are unequal', () {
      final other = build().copyWith(
        newPRs: [
          PersonalRecord(
            id: 2,
            exerciseId: 2,
            weight: 200,
            reps: 1,
            estimated1RM: 200,
            achievedAt: at,
          ),
        ],
      );
      expect(build(), isNot(equals(other)));
    });
  });
}
