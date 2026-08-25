import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalsync/core/enums/glucose_source.dart';
import 'package:vitalsync/core/enums/health_data_source_kind.dart';
import 'package:vitalsync/core/enums/health_sample_type.dart';
import 'package:vitalsync/core/enums/meal_context.dart';
import 'package:vitalsync/core/enums/sync_status.dart';
import 'package:vitalsync/data/local/database.dart';
import 'package:vitalsync/data/repositories/health/glucose_repository_impl.dart';
import 'package:vitalsync/data/repositories/health/health_sample_repository_impl.dart';
import 'package:vitalsync/data/repositories/health/meal_repository_impl.dart';
import 'package:vitalsync/data/repositories/shared/calibration_metric_repository_impl.dart';
import 'package:vitalsync/domain/entities/health/glucose_reading.dart';
import 'package:vitalsync/domain/entities/health/health_sample.dart';
import 'package:vitalsync/domain/entities/health/meal.dart';
import 'package:vitalsync/domain/entities/shared/calibration_metric.dart';

/// Exercises the 2.0 measurement-layer data chain end to end: repository ->
/// model -> DAO -> Drift. Covers the parts a compile-time check cannot catch —
/// nullable text enums, the JSON-encoded tag and counter columns, the
/// externalId unique index, and GDPR export/erasure of the new tables.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  final now = DateTime.utc(2026, 8, 25, 9);

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  test('glucose roundtrip, nullable enum, update, dedupe', () async {
    final repo = GlucoseRepositoryImpl(db.glucoseDao, db);
    final id = await repo.insert(
      GlucoseReading(
        id: 0,
        valueMgDl: 104.5,
        measuredAt: now,
        source: GlucoseSource.healthKit,
        externalId: 'HK-1',
        mealContext: MealContext.postMeal,
        lastModifiedAt: now,
        createdAt: now,
      ),
    );
    var row = await repo.getById(id);
    expect(row!.valueMgDl, 104.5);
    expect(row.mealContext, MealContext.postMeal);
    expect(row.source, GlucoseSource.healthKit);

    // nullable textEnum stays null
    final id2 = await repo.insert(
      GlucoseReading(
        id: 0,
        valueMgDl: 88,
        measuredAt: now,
        source: GlucoseSource.manual,
        lastModifiedAt: now,
        createdAt: now,
      ),
    );
    expect((await repo.getById(id2))!.mealContext, null);

    // two manual rows with NULL externalId must coexist under the unique index
    await repo.insert(
      GlucoseReading(
        id: 0,
        valueMgDl: 91,
        measuredAt: now,
        source: GlucoseSource.manual,
        lastModifiedAt: now,
        createdAt: now,
      ),
    );
    expect(await repo.getAll(), hasLength(3));

    expect(await repo.existsByExternalId('HK-1'), isTrue);
    expect(await repo.existsByExternalId('HK-2'), isFalse);

    await repo.update(row.copyWith(notes: 'edited', syncStatus: SyncStatus.pending));
    row = await repo.getById(id);
    expect(row!.notes, 'edited');
    expect(row.syncStatus, SyncStatus.pending);

    // duplicate externalId must be rejected by the unique index
    expect(
      () => repo.insert(
        GlucoseReading(
          id: 0,
          valueMgDl: 100,
          measuredAt: now,
          source: GlucoseSource.healthKit,
          externalId: 'HK-1',
          lastModifiedAt: now,
          createdAt: now,
        ),
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('upsertFromRemote survives an externalId held by another local row',
      () async {
    // Two devices import the same HealthKit sample and give it different local
    // IDs; whichever reached the cloud first comes back down in a pull. The
    // unique index must not turn that into a failed sync.
    await db.glucoseDao.insert(
      GlucoseReadingsCompanion.insert(
        valueMgDl: 100,
        measuredAt: now,
        source: GlucoseSource.healthKit,
        externalId: const Value('HK-1'),
      ),
    );
    await db.glucoseDao.upsertFromRemote(42, {
      'valueMgDl': 105,
      'measuredAt': now.toIso8601String(),
      'source': 'healthKit',
      'externalId': 'HK-1',
      'lastModifiedAt': now.toIso8601String(),
      'createdAt': now.toIso8601String(),
    });

    final rows = await db.glucoseDao.getAll();
    expect(rows, hasLength(1));
    expect(rows.single.id, 42);
    expect(rows.single.valueMgDl, 105);
    expect(rows.single.syncStatus, SyncStatus.synced);

    // A second pull of the same record is a no-op, not a duplicate.
    await db.glucoseDao.upsertFromRemote(42, {
      'valueMgDl': 105,
      'measuredAt': now.toIso8601String(),
      'source': 'healthKit',
      'externalId': 'HK-1',
      'lastModifiedAt': now.toIso8601String(),
      'createdAt': now.toIso8601String(),
    });
    expect(await db.glucoseDao.getAll(), hasLength(1));
  });

  test('health sample upsertFromRemote resolves the same externalId clash',
      () async {
    await db.healthSampleDao.insert(
      HealthSamplesCompanion.insert(
        type: HealthSampleType.steps,
        startAt: now,
        value: 500,
        unit: 'count',
        source: HealthDataSourceKind.healthKit,
        externalId: const Value('HK-steps'),
      ),
    );
    await db.healthSampleDao.upsertFromRemote(77, {
      'type': 'steps',
      'startAt': now.toIso8601String(),
      'value': 900,
      'unit': 'count',
      'source': 'healthKit',
      'externalId': 'HK-steps',
      'lastModifiedAt': now.toIso8601String(),
      'createdAt': now.toIso8601String(),
    });

    final rows = await db.healthSampleDao.getAll();
    expect(rows, hasLength(1));
    expect(rows.single.id, 77);
    expect(rows.single.value, 900);
  });

  test('meal tags json roundtrip', () async {
    final repo = MealRepositoryImpl(db.mealDao, db);
    final id = await repo.insert(
      Meal(
        id: 0,
        name: 'Oatmeal',
        eatenAt: now,
        tags: const ['breakfast', 'home_cooked'],
        lastModifiedAt: now,
        createdAt: now,
      ),
    );
    final row = await repo.getById(id);
    expect(row!.tags, ['breakfast', 'home_cooked']);
    await repo.update(row.copyWith(tags: const ['lunch']));
    expect((await repo.getById(id))!.tags, ['lunch']);
  });

  test('health sample type filter and dedupe', () async {
    final repo = HealthSampleRepositoryImpl(db.healthSampleDao);
    for (final t in HealthSampleType.values) {
      await repo.insert(
        HealthSample(
          id: 0,
          type: t,
          startAt: now,
          endAt: now.add(const Duration(minutes: 30)),
          value: 1,
          unit: 'count',
          source: HealthDataSourceKind.healthKit,
          externalId: 'HK-${t.name}',
          lastModifiedAt: now,
          createdAt: now,
        ),
      );
    }
    final steps = await repo.getByTypeAndRange(
      HealthSampleType.steps,
      now.subtract(const Duration(days: 1)),
      now.add(const Duration(days: 1)),
    );
    expect(steps, hasLength(1));
    expect(steps.single.type, HealthSampleType.steps);
    expect(await repo.existsByExternalId('HK-sleep'), isTrue);
  });

  test('calibration metric map roundtrip', () async {
    final repo = CalibrationMetricRepositoryImpl(db.calibrationMetricDao, db);
    final id = await repo.insert(
      CalibrationMetric(
        id: 0,
        weekStart: now,
        mealsLogged: 12,
        glucoseReadings: 30,
        manualReadings: 4,
        coveredMeals: 9,
        uncoveredReasons: const {'noReadingBefore': 2, 'noReadingAfter': 1},
        appVersion: '2.0.0',
        lastModifiedAt: now,
        createdAt: now,
      ),
    );
    final row = await repo.getById(id);
    expect(row!.uncoveredReasons, {'noReadingBefore': 2, 'noReadingAfter': 1});
    expect(await repo.getByWeekStart(now), isA<CalibrationMetric>());
    await repo.update(row.copyWith(coveredMeals: 10));
    expect((await repo.getById(id))!.coveredMeals, 10);
  });

  test('export and delete cover the new tables', () async {
    await db.glucoseDao.insert(
      GlucoseReadingsCompanion.insert(
        valueMgDl: 99,
        measuredAt: now,
        source: GlucoseSource.manual,
      ),
    );
    await db.mealDao.insert(
      MealsCompanion.insert(name: 'Soup', eatenAt: now, tags: '[]'),
    );
    await db.healthSampleDao.insert(
      HealthSamplesCompanion.insert(
        type: HealthSampleType.steps,
        startAt: now,
        value: 500,
        unit: 'count',
        source: HealthDataSourceKind.healthKit,
      ),
    );
    await db.calibrationMetricDao.insert(
      CalibrationMetricsCompanion.insert(
        weekStart: now,
        mealsLogged: 1,
        glucoseReadings: 1,
        manualReadings: 1,
        coveredMeals: 1,
        uncoveredReasons: '{}',
        appVersion: '2.0.0',
      ),
    );

    final export = await db.exportAllData();
    expect(export['database_version'], 2);
    final health = export['health']! as Map<String, dynamic>;
    expect(health['glucose_readings'], hasLength(1));
    expect(health['meals'], hasLength(1));
    expect(health['health_samples'], hasLength(1));
    expect(export['calibration_metrics'], hasLength(1));

    await db.deleteAllData();
    expect(await db.glucoseDao.getAll(), isEmpty);
    expect(await db.mealDao.getAll(), isEmpty);
    expect(await db.healthSampleDao.getAll(), isEmpty);
    expect(await db.calibrationMetricDao.getAll(), isEmpty);
  });
}
