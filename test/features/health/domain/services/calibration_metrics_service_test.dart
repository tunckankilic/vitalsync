// Tests for the opt-in calibration metrics collection.
//
// Two things matter here and both are privacy contracts:
//
// 1. While consent is off nothing is produced — not written and withheld,
//    but never created, and no repository is even read.
// 2. What is produced carries counts only. The assertions below walk every
//    field of the stored row to make sure no health data slipped in.

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vitalsync/core/enums/glucose_source.dart';
import 'package:vitalsync/core/enums/sync_status.dart';
import 'package:vitalsync/domain/entities/health/glucose_reading.dart';
import 'package:vitalsync/domain/entities/health/meal.dart';
import 'package:vitalsync/domain/entities/shared/calibration_metric.dart';
import 'package:vitalsync/domain/repositories/health/glucose_repository.dart';
import 'package:vitalsync/domain/repositories/health/health_sample_repository.dart';
import 'package:vitalsync/domain/repositories/health/meal_repository.dart';
import 'package:vitalsync/domain/repositories/shared/calibration_metric_repository.dart';
import 'package:vitalsync/features/health/domain/services/calibration_metrics_service.dart';
import 'package:vitalsync/features/health/domain/services/meal_data_coverage_service.dart';

class _MockMealRepository extends Mock implements MealRepository {}

class _MockGlucoseRepository extends Mock implements GlucoseRepository {}

class _MockHealthSampleRepository extends Mock
    implements HealthSampleRepository {}

class _MockCalibrationMetricRepository extends Mock
    implements CalibrationMetricRepository {}

void main() {
  final weekStart = DateTime(2026, 8, 24);
  final mealTime = weekStart.add(const Duration(hours: 8));

  late _MockMealRepository mealRepository;
  late _MockGlucoseRepository glucoseRepository;
  late _MockHealthSampleRepository healthSampleRepository;
  late _MockCalibrationMetricRepository metricRepository;
  late bool consentGranted;

  Meal mealAt(int id, DateTime eatenAt) => Meal(
    id: id,
    name: 'kahvaltı $id',
    eatenAt: eatenAt,
    tags: const ['breakfast'],
    notes: 'a private note',
    lastModifiedAt: eatenAt,
    createdAt: eatenAt,
  );

  GlucoseReading readingAt(
    int id,
    DateTime measuredAt, {
    GlucoseSource source = GlucoseSource.manual,
  }) => GlucoseReading(
    id: id,
    valueMgDl: 137.5,
    measuredAt: measuredAt,
    source: source,
    lastModifiedAt: measuredAt,
    createdAt: measuredAt,
  );

  CalibrationMetricsService buildService() {
    return CalibrationMetricsService(
      coverageService: MealDataCoverageService(
        mealRepository: mealRepository,
        glucoseRepository: glucoseRepository,
        healthSampleRepository: healthSampleRepository,
      ),
      mealRepository: mealRepository,
      glucoseRepository: glucoseRepository,
      metricRepository: metricRepository,
      isConsentGranted: () => consentGranted,
      appVersion: '1.0.0',
    );
  }

  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(
      CalibrationMetric(
        id: 0,
        weekStart: DateTime(2026),
        mealsLogged: 0,
        glucoseReadings: 0,
        manualReadings: 0,
        coveredMeals: 0,
        uncoveredReasons: const {},
        appVersion: '',
        lastModifiedAt: DateTime(2026),
        createdAt: DateTime(2026),
      ),
    );
  });

  setUp(() {
    mealRepository = _MockMealRepository();
    glucoseRepository = _MockGlucoseRepository();
    healthSampleRepository = _MockHealthSampleRepository();
    metricRepository = _MockCalibrationMetricRepository();
    consentGranted = true;

    when(
      () => healthSampleRepository.getByDateRange(any(), any()),
    ).thenAnswer((_) async => []);
    when(
      () => metricRepository.getByWeekStart(any()),
    ).thenAnswer((_) async => null);
    when(() => metricRepository.insert(any())).thenAnswer((_) async => 7);
    when(() => metricRepository.update(any())).thenAnswer((_) async {});
  });

  group('consent off', () {
    setUp(() {
      consentGranted = false;
      when(
        () => mealRepository.getByDateRange(any(), any()),
      ).thenAnswer((_) async => [mealAt(1, mealTime)]);
      when(
        () => glucoseRepository.getByDateRange(any(), any()),
      ).thenAnswer((_) async => [readingAt(1, mealTime)]);
    });

    test('produces no metric', () async {
      final metric = await buildService().collectForWeek(weekStart);

      expect(metric, isNull);
    });

    test('writes nothing', () async {
      await buildService().collectForWeek(weekStart);

      verifyNever(() => metricRepository.insert(any()));
      verifyNever(() => metricRepository.update(any()));
    });

    test('does not even read the health data', () async {
      await buildService().collectForWeek(weekStart);

      verifyNever(() => mealRepository.getByDateRange(any(), any()));
      verifyNever(() => glucoseRepository.getByDateRange(any(), any()));
    });
  });

  group('consent on', () {
    setUp(() {
      when(() => mealRepository.getByDateRange(any(), any())).thenAnswer(
        (_) async => [
          mealAt(1, mealTime),
          mealAt(2, mealTime.add(const Duration(days: 2))),
        ],
      );
      when(() => glucoseRepository.getByDateRange(any(), any())).thenAnswer(
        (_) async => [
          readingAt(1, mealTime),
          readingAt(2, mealTime.add(const Duration(hours: 1))),
          readingAt(
            3,
            mealTime.add(const Duration(hours: 2)),
            source: GlucoseSource.healthKit,
          ),
        ],
      );
    });

    test('stores the counts for the week', () async {
      await buildService().collectForWeek(weekStart);

      final stored =
          verify(() => metricRepository.insert(captureAny())).captured.single
              as CalibrationMetric;

      expect(stored.weekStart, weekStart);
      expect(stored.mealsLogged, 2);
      expect(stored.glucoseReadings, 3);
      expect(stored.manualReadings, 2);
      expect(stored.appVersion, '1.0.0');
      expect(stored.syncStatus, SyncStatus.pending);
    });

    test('carries no health data at all', () async {
      await buildService().collectForWeek(weekStart);

      final stored =
          verify(() => metricRepository.insert(captureAny())).captured.single
              as CalibrationMetric;

      // Every value in the row is a count, a date or the app version.
      //
      // Timestamps are masked before the numeric check: `lastModifiedAt` and
      // `createdAt` are wall-clock values carrying arbitrary digits, so a
      // millisecond component of .137 made the '137' assertion below fail at
      // random — roughly one run in a thousand. Masking keeps the guarantee
      // (no measurement value in the row) without the false positive.
      final serialized = stored.toString().replaceAll(
        RegExp(r'\d{4}-\d{2}-\d{2}[ T][\d:.]+Z?'),
        '<timestamp>',
      );
      expect(serialized, isNot(contains('kahvaltı')));
      expect(serialized, isNot(contains('private note')));
      expect(serialized, isNot(contains('137')));
      expect(serialized, isNot(contains('breakfast')));

      // The mask must not have swallowed the whole string and made the
      // checks above vacuous.
      expect(serialized, contains('CalibrationMetric('));
      expect(serialized, contains('appVersion: 1.0.0'));

      // The reason map keys are enum names, never user text.
      for (final key in stored.uncoveredReasons.keys) {
        expect(UncoveredReason.values.map((r) => r.name), contains(key));
      }
    });

    test('counts covered meals and tallies the rest by reason', () async {
      // The two meals are two days apart, so neither is the other's
      // neighbour. Only the first has readings around it.
      await buildService().collectForWeek(weekStart);

      final stored =
          verify(() => metricRepository.insert(captureAny())).captured.single
              as CalibrationMetric;

      expect(stored.coveredMeals, 1);
      expect(stored.uncoveredReasons, {UncoveredReason.noReadings.name: 1});
    });

    test('re-running a week updates the existing row', () async {
      final existing = CalibrationMetric(
        id: 42,
        weekStart: weekStart,
        mealsLogged: 0,
        glucoseReadings: 0,
        manualReadings: 0,
        coveredMeals: 0,
        uncoveredReasons: const {},
        appVersion: '0.9.0',
        lastModifiedAt: weekStart,
        createdAt: weekStart,
      );
      when(
        () => metricRepository.getByWeekStart(weekStart),
      ).thenAnswer((_) async => existing);

      await buildService().collectForWeek(weekStart);

      verifyNever(() => metricRepository.insert(any()));
      final stored =
          verify(() => metricRepository.update(captureAny())).captured.single
              as CalibrationMetric;

      expect(stored.id, 42);
      expect(stored.createdAt, weekStart);
      expect(stored.mealsLogged, 2);
    });

    test('returns the row with the id the repository assigned', () async {
      final metric = await buildService().collectForWeek(weekStart);

      expect(metric, isNotNull);
      expect(metric!.id, 7);
    });
  });
}
