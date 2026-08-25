import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalsync/core/enums/glucose_source.dart';
import 'package:vitalsync/core/enums/sync_enums.dart';
import 'package:vitalsync/core/sync/sync_service.dart';
import 'package:vitalsync/data/local/database.dart';
import 'package:vitalsync/data/repositories/health/glucose_repository_impl.dart';
import 'package:vitalsync/data/repositories/health/meal_repository_impl.dart';
import 'package:vitalsync/data/repositories/shared/calibration_metric_repository_impl.dart';
import 'package:vitalsync/domain/entities/health/glucose_reading.dart';
import 'package:vitalsync/domain/entities/health/meal.dart';
import 'package:vitalsync/domain/entities/shared/calibration_metric.dart';

/// Guards the cost decision behind glucose sync: a CGM writes roughly 288
/// readings a day into Apple Health, and every one of them is re-importable on
/// a new device. Pushing them to DynamoDB would multiply write cost for
/// nothing, so only hand-entered readings may reach the sync queue. If this
/// test goes green for a healthKit-sourced reading, the bill grows silently.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late GlucoseRepositoryImpl glucoseRepo;

  final now = DateTime.utc(2026, 8, 25, 9);

  GlucoseReading reading({
    required GlucoseSource source,
    String? externalId,
    double value = 98,
  }) {
    return GlucoseReading(
      id: 0,
      valueMgDl: value,
      measuredAt: now,
      source: source,
      externalId: externalId,
      lastModifiedAt: now,
      createdAt: now,
    );
  }

  Future<List<SyncQueueData>> queue() => db.syncDao.getPendingItems();

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    glucoseRepo = GlucoseRepositoryImpl(db.glucoseDao, db);
  });

  tearDown(() async => db.close());

  group('glucose sync queueing', () {
    test('a manual reading is queued for push', () async {
      final id = await glucoseRepo.insert(reading(source: GlucoseSource.manual));

      final items = await queue();
      expect(items, hasLength(1));
      expect(items.single.targetTable, 'glucose_readings');
      expect(items.single.recordId, id);
      expect(items.single.operation, SyncOperation.insert);

      final payload = jsonDecode(items.single.payload) as Map<String, dynamic>;
      expect(payload['valueMgDl'], 98);
      expect(payload['source'], 'manual');
    });

    test('a HealthKit reading is NOT queued', () async {
      await glucoseRepo.insert(
        reading(source: GlucoseSource.healthKit, externalId: 'HK-1'),
      );

      expect(await queue(), isEmpty);
      // The row itself is still stored locally.
      expect(await db.glucoseDao.getAll(), hasLength(1));
    });

    test('updating a manual reading is queued', () async {
      final id = await glucoseRepo.insert(reading(source: GlucoseSource.manual));
      final stored = (await glucoseRepo.getById(id))!;

      await glucoseRepo.update(stored.copyWith(notes: 'after breakfast'));

      final items = await queue();
      expect(items, hasLength(2));
      expect(items.last.operation, SyncOperation.update);
    });

    test('updating a HealthKit reading is NOT queued', () async {
      final id = await glucoseRepo.insert(
        reading(source: GlucoseSource.healthKit, externalId: 'HK-1'),
      );
      final stored = (await glucoseRepo.getById(id))!;

      await glucoseRepo.update(stored.copyWith(notes: 'edited'));

      expect(await queue(), isEmpty);
    });

    test('deleting a manual reading is queued', () async {
      final id = await glucoseRepo.insert(reading(source: GlucoseSource.manual));
      await glucoseRepo.delete(id);

      final items = await queue();
      expect(items, hasLength(2));
      expect(items.last.operation, SyncOperation.delete);
      expect(items.last.recordId, id);
    });

    test('deleting a HealthKit reading is NOT queued', () async {
      final id = await glucoseRepo.insert(
        reading(source: GlucoseSource.healthKit, externalId: 'HK-1'),
      );
      await glucoseRepo.delete(id);

      expect(await queue(), isEmpty);
      expect(await db.glucoseDao.getAll(), isEmpty);
    });

    test('a mixed session queues only the manual readings', () async {
      await glucoseRepo.insert(
        reading(source: GlucoseSource.healthKit, externalId: 'HK-1'),
      );
      await glucoseRepo.insert(reading(source: GlucoseSource.manual, value: 88));
      await glucoseRepo.insert(
        reading(source: GlucoseSource.healthKit, externalId: 'HK-2'),
      );
      await glucoseRepo.insert(
        reading(source: GlucoseSource.manual, value: 121),
      );

      final items = await queue();
      expect(items, hasLength(2));
      for (final item in items) {
        final payload = jsonDecode(item.payload) as Map<String, dynamic>;
        expect(payload['source'], 'manual');
      }
    });
  });

  group('meal and calibration metric sync queueing', () {
    test('a meal is queued in full', () async {
      final repo = MealRepositoryImpl(db.mealDao, db);
      final id = await repo.insert(
        Meal(
          id: 0,
          name: 'Oatmeal',
          eatenAt: now,
          tags: const ['breakfast'],
          lastModifiedAt: now,
          createdAt: now,
        ),
      );

      final items = await queue();
      expect(items, hasLength(1));
      expect(items.single.targetTable, 'meals');
      expect(items.single.recordId, id);
    });

    test('a calibration metric row is queued', () async {
      final repo = CalibrationMetricRepositoryImpl(db.calibrationMetricDao, db);
      await repo.insert(
        CalibrationMetric(
          id: 0,
          weekStart: now,
          mealsLogged: 5,
          glucoseReadings: 20,
          manualReadings: 3,
          coveredMeals: 4,
          uncoveredReasons: const {'noReadingAfter': 1},
          appVersion: '2.0.0',
          lastModifiedAt: now,
          createdAt: now,
        ),
      );

      final items = await queue();
      expect(items, hasLength(1));
      expect(items.single.targetTable, 'calibration_metrics');
    });
  });

  group('push payload survives a pull round trip', () {
    // The queue payload is a model's toJson(), where tags and the uncovered
    // reason counters are decoded structures. upsertFromRemote reads the same
    // payload back off the wire, so a shape mismatch here would only surface
    // in production as a failed pull.
    test('a meal payload can be applied by upsertFromRemote', () async {
      final repo = MealRepositoryImpl(db.mealDao, db);
      await repo.insert(
        Meal(
          id: 0,
          name: 'Oatmeal',
          eatenAt: now,
          tags: const ['breakfast', 'home_cooked'],
          lastModifiedAt: now,
          createdAt: now,
        ),
      );
      final payload =
          jsonDecode((await queue()).single.payload) as Map<String, dynamic>;

      await db.mealDao.upsertFromRemote(900, payload);

      final pulled = await db.mealDao.getById(900);
      expect(pulled, isNotNull);
      expect(jsonDecode(pulled!.tags), ['breakfast', 'home_cooked']);
    });

    test('a calibration payload can be applied by upsertFromRemote', () async {
      final repo = CalibrationMetricRepositoryImpl(db.calibrationMetricDao, db);
      await repo.insert(
        CalibrationMetric(
          id: 0,
          weekStart: now,
          mealsLogged: 5,
          glucoseReadings: 20,
          manualReadings: 3,
          coveredMeals: 4,
          uncoveredReasons: const {'noReadingAfter': 1},
          appVersion: '2.0.0',
          lastModifiedAt: now,
          createdAt: now,
        ),
      );
      final payload =
          jsonDecode((await queue()).single.payload) as Map<String, dynamic>;

      await db.calibrationMetricDao.upsertFromRemote(901, payload);

      final pulled = await db.calibrationMetricDao.getById(901);
      expect(pulled, isNotNull);
      expect(jsonDecode(pulled!.uncoveredReasons), {'noReadingAfter': 1});
    });

    test('a glucose payload can be applied by upsertFromRemote', () async {
      await glucoseRepo.insert(
        reading(source: GlucoseSource.manual, value: 117),
      );
      final payload =
          jsonDecode((await queue()).single.payload) as Map<String, dynamic>;

      await db.glucoseDao.upsertFromRemote(902, payload);

      final pulled = await db.glucoseDao.getById(902);
      expect(pulled!.valueMgDl, 117);
      expect(pulled.source, GlucoseSource.manual);
    });
  });

  group('sync collection wiring', () {
    test('the three cloud collections are registered, health_samples is not',
        () {
      expect(SyncService.tablesToSync, contains('meals'));
      expect(SyncService.tablesToSync, contains('glucose_readings'));
      expect(SyncService.tablesToSync, contains('calibration_metrics'));
      expect(SyncService.tablesToSync, isNot(contains('health_samples')));
    });

    test('every queued collection is one SyncService knows how to pull',
        () async {
      await glucoseRepo.insert(reading(source: GlucoseSource.manual));
      await MealRepositoryImpl(db.mealDao, db).insert(
        Meal(
          id: 0,
          name: 'Soup',
          eatenAt: now,
          tags: const [],
          lastModifiedAt: now,
          createdAt: now,
        ),
      );

      for (final item in await queue()) {
        expect(SyncService.tablesToSync, contains(item.targetTable));
      }
    });
  });
}
