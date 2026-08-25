// Tests for the meal data coverage service.
//
// The service answers one question — was enough measurement data recorded
// around this meal — and these tests pin down each of the four ways the
// answer can be "no", plus the case where it is "yes".
//
// Nothing here asserts anything about glucose values themselves. If a test
// ever needs to, the service has grown past its scope.

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vitalsync/core/enums/glucose_source.dart';
import 'package:vitalsync/core/enums/health_data_source_kind.dart';
import 'package:vitalsync/core/enums/health_sample_type.dart';
import 'package:vitalsync/domain/entities/health/glucose_reading.dart';
import 'package:vitalsync/domain/entities/health/health_sample.dart';
import 'package:vitalsync/domain/entities/health/meal.dart';
import 'package:vitalsync/domain/repositories/health/glucose_repository.dart';
import 'package:vitalsync/domain/repositories/health/health_sample_repository.dart';
import 'package:vitalsync/domain/repositories/health/meal_repository.dart';
import 'package:vitalsync/features/health/domain/services/meal_data_coverage_service.dart';

class _MockMealRepository extends Mock implements MealRepository {}

class _MockGlucoseRepository extends Mock implements GlucoseRepository {}

class _MockHealthSampleRepository extends Mock
    implements HealthSampleRepository {}

void main() {
  // Monday 08:00 — the meal every test is built around.
  final mealTime = DateTime(2026, 8, 24, 8);

  late MealDataCoverageService service;

  Meal mealAt(int id, DateTime eatenAt) => Meal(
    id: id,
    name: 'meal $id',
    eatenAt: eatenAt,
    tags: const [],
    lastModifiedAt: eatenAt,
    createdAt: eatenAt,
  );

  GlucoseReading readingAt(int id, DateTime measuredAt) => GlucoseReading(
    id: id,
    valueMgDl: 100,
    measuredAt: measuredAt,
    source: GlucoseSource.manual,
    lastModifiedAt: measuredAt,
    createdAt: measuredAt,
  );

  HealthSample sampleAt(
    int id,
    HealthSampleType type,
    DateTime startAt, {
    DateTime? endAt,
    double value = 1,
  }) => HealthSample(
    id: id,
    type: type,
    startAt: startAt,
    endAt: endAt,
    value: value,
    unit: 'unit',
    source: HealthDataSourceKind.healthKit,
    lastModifiedAt: startAt,
    createdAt: startAt,
  );

  /// Readings that satisfy the thresholds: one at the meal, one an hour in,
  /// one at the end of the two-hour window.
  List<GlucoseReading> coveringReadings() => [
    readingAt(1, mealTime),
    readingAt(2, mealTime.add(const Duration(hours: 1))),
    readingAt(3, mealTime.add(const Duration(hours: 2))),
  ];

  MealCoverage evaluate({
    List<Meal> otherMeals = const [],
    List<GlucoseReading> readings = const [],
    List<HealthSample> samples = const [],
  }) {
    return service.evaluateMeal(
      meal: mealAt(1, mealTime),
      otherMeals: otherMeals,
      readings: readings,
      samples: samples,
    );
  }

  setUp(() {
    service = MealDataCoverageService(
      mealRepository: _MockMealRepository(),
      glucoseRepository: _MockGlucoseRepository(),
      healthSampleRepository: _MockHealthSampleRepository(),
    );
  });

  group('covered', () {
    test('readings spanning the window with no gap too wide', () {
      final coverage = evaluate(readings: coveringReadings());

      expect(coverage.isCovered, isTrue);
      expect(coverage.reason, isNull);
    });

    test('the meal itself does not count as a neighbour', () {
      final coverage = evaluate(
        otherMeals: [mealAt(1, mealTime)],
        readings: coveringReadings(),
      );

      expect(coverage.isCovered, isTrue);
    });

    test('activity below the energy threshold does not disqualify', () {
      final coverage = evaluate(
        readings: coveringReadings(),
        samples: [
          sampleAt(
            1,
            HealthSampleType.activeEnergy,
            mealTime.add(const Duration(minutes: 30)),
            value: MealDataCoverageService.activeEnergyThresholdKcal - 1,
          ),
        ],
      );

      expect(coverage.isCovered, isTrue);
    });

    test('steps and sleep in the window are not activity', () {
      final coverage = evaluate(
        readings: coveringReadings(),
        samples: [
          sampleAt(
            1,
            HealthSampleType.steps,
            mealTime.add(const Duration(minutes: 10)),
            value: 4000,
          ),
          sampleAt(
            2,
            HealthSampleType.sleep,
            mealTime.add(const Duration(minutes: 20)),
          ),
        ],
      );

      expect(coverage.isCovered, isTrue);
    });
  });

  group('uncovered', () {
    test('noReadings when the window holds none at all', () {
      final coverage = evaluate();

      expect(coverage.reason, UncoveredReason.noReadings);
    });

    test('noReadings when the window holds fewer than the minimum', () {
      final coverage = evaluate(
        readings: [
          readingAt(1, mealTime),
          readingAt(2, mealTime.add(const Duration(hours: 1))),
        ],
      );

      expect(coverage.reason, UncoveredReason.noReadings);
    });

    test('noReadings when the readings fall outside the window', () {
      final coverage = evaluate(
        readings: [
          readingAt(1, mealTime.subtract(const Duration(minutes: 1))),
          readingAt(2, mealTime.add(const Duration(hours: 3))),
          readingAt(3, mealTime.add(const Duration(hours: 4))),
        ],
      );

      expect(coverage.reason, UncoveredReason.noReadings);
    });

    test('gapInData when enough readings bunch at the start', () {
      final coverage = evaluate(
        readings: [
          readingAt(1, mealTime),
          readingAt(2, mealTime.add(const Duration(minutes: 5))),
          readingAt(3, mealTime.add(const Duration(minutes: 10))),
        ],
      );

      expect(coverage.reason, UncoveredReason.gapInData);
    });

    test('gapInData when a stretch mid-window is unmeasured', () {
      final coverage = evaluate(
        readings: [
          readingAt(1, mealTime),
          readingAt(2, mealTime.add(const Duration(minutes: 75))),
          readingAt(3, mealTime.add(const Duration(minutes: 120))),
        ],
      );

      expect(coverage.reason, UncoveredReason.gapInData);
    });

    test('overlappingMeal when another meal shares the window', () {
      final coverage = evaluate(
        otherMeals: [mealAt(2, mealTime.add(const Duration(hours: 1)))],
        readings: coveringReadings(),
      );

      expect(coverage.reason, UncoveredReason.overlappingMeal);
    });

    test('overlappingMeal when another meal is just before it', () {
      final coverage = evaluate(
        otherMeals: [mealAt(2, mealTime.subtract(const Duration(minutes: 30)))],
        readings: coveringReadings(),
      );

      expect(coverage.reason, UncoveredReason.overlappingMeal);
    });

    test('a meal beyond the separation is not an overlap', () {
      final coverage = evaluate(
        otherMeals: [
          mealAt(2, mealTime.subtract(const Duration(hours: 2))),
          mealAt(3, mealTime.add(const Duration(hours: 4))),
        ],
        readings: coveringReadings(),
      );

      expect(coverage.isCovered, isTrue);
    });

    test('activityInWindow when a workout overlaps it', () {
      final coverage = evaluate(
        readings: coveringReadings(),
        samples: [
          sampleAt(
            1,
            HealthSampleType.workout,
            mealTime.add(const Duration(minutes: 30)),
            endAt: mealTime.add(const Duration(minutes: 60)),
          ),
        ],
      );

      expect(coverage.reason, UncoveredReason.activityInWindow);
    });

    test('activityInWindow when active energy passes the threshold', () {
      final coverage = evaluate(
        readings: coveringReadings(),
        samples: [
          sampleAt(
            1,
            HealthSampleType.activeEnergy,
            mealTime.add(const Duration(minutes: 15)),
            value: MealDataCoverageService.activeEnergyThresholdKcal,
          ),
          sampleAt(
            2,
            HealthSampleType.activeEnergy,
            mealTime.add(const Duration(minutes: 45)),
            value: 1,
          ),
        ],
      );

      expect(coverage.reason, UncoveredReason.activityInWindow);
    });

    test('a workout that ends before the meal is not in the window', () {
      final coverage = evaluate(
        readings: coveringReadings(),
        samples: [
          sampleAt(
            1,
            HealthSampleType.workout,
            mealTime.subtract(const Duration(hours: 2)),
            endAt: mealTime.subtract(const Duration(hours: 1)),
          ),
        ],
      );

      expect(coverage.isCovered, isTrue);
    });
  });

  group('precedence', () {
    // Window validity is reported ahead of what was measured inside it.
    test('an overlapping meal outranks missing readings', () {
      final coverage = evaluate(
        otherMeals: [mealAt(2, mealTime.add(const Duration(minutes: 30)))],
      );

      expect(coverage.reason, UncoveredReason.overlappingMeal);
    });

    test('activity outranks missing readings', () {
      final coverage = evaluate(
        samples: [
          sampleAt(
            1,
            HealthSampleType.workout,
            mealTime.add(const Duration(minutes: 30)),
          ),
        ],
      );

      expect(coverage.reason, UncoveredReason.activityInWindow);
    });
  });

  group('MealCoverageSummary', () {
    test('tallies verdicts by reason', () {
      final summary = MealCoverageSummary.from([
        const MealCoverage.covered(1),
        const MealCoverage.covered(2),
        const MealCoverage.uncovered(3, UncoveredReason.noReadings),
        const MealCoverage.uncovered(4, UncoveredReason.noReadings),
        const MealCoverage.uncovered(5, UncoveredReason.activityInWindow),
      ]);

      expect(summary.mealsEvaluated, 5);
      expect(summary.coveredMeals, 2);
      expect(summary.uncoveredMeals, 3);
      expect(summary.reasonsByName(), {
        'noReadings': 2,
        'activityInWindow': 1,
      });
    });

    test('is empty for no meals', () {
      final summary = MealCoverageSummary.from([]);

      expect(summary.mealsEvaluated, 0);
      expect(summary.coveredMeals, 0);
      expect(summary.reasonsByName(), isEmpty);
    });
  });
}
