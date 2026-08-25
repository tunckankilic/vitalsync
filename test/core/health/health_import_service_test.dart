import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalsync/core/constants/app_constants.dart';
import 'package:vitalsync/core/enums/glucose_source.dart';
import 'package:vitalsync/core/enums/health_sample_type.dart';
import 'package:vitalsync/core/errors/exceptions.dart';
import 'package:vitalsync/core/health/health_data_source.dart';
import 'package:vitalsync/core/health/health_import_service.dart';
import 'package:vitalsync/data/local/database.dart';

/// A scripted [HealthDataSource] standing in for Apple Health.
///
/// Keeps the tests off the platform channel and lets each case describe an
/// authorization state and a sample set directly.
class _FakeHealthDataSource implements HealthDataSource {
  bool authorized = true;
  bool grantRequest = true;
  List<HealthSampleDto> samples = const [];

  List<HealthSampleKind>? lastRequestedKinds;
  DateTime? lastSince;
  int disconnectCount = 0;

  @override
  Future<bool> requestPermissions() async {
    if (grantRequest) authorized = true;
    return grantRequest;
  }

  @override
  Future<bool> isAuthorized() async => authorized;

  @override
  Future<List<HealthSampleDto>> readSamples({
    required List<HealthSampleKind> kinds,
    required DateTime since,
  }) async {
    lastRequestedKinds = kinds;
    lastSince = since;
    return samples;
  }

  @override
  Future<void> disconnect() async => disconnectCount++;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late _FakeHealthDataSource source;
  late HealthImportService service;

  final measuredAt = DateTime.utc(2026, 8, 20, 8, 30);
  final since = DateTime.utc(2026, 8, 1);

  HealthSampleDto glucose({String? externalId, double value = 96}) {
    return HealthSampleDto(
      kind: HealthSampleKind.bloodGlucose,
      startAt: measuredAt,
      endAt: measuredAt,
      value: value,
      unit: 'MILLIGRAM_PER_DECILITER',
      externalId: externalId,
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    source = _FakeHealthDataSource();
    service = HealthImportService(
      source: source,
      glucoseDao: db.glucoseDao,
      healthSampleDao: db.healthSampleDao,
    );
  });

  tearDown(() async => db.close());

  group('authorization', () {
    test('importSince throws HealthDataException when access is not held',
        () async {
      source.authorized = false;

      expect(
        () => service.importSince(since),
        throwsA(isA<HealthDataException>()),
      );
    });

    test('requestPermissions throws HealthDataException when declined',
        () async {
      source.grantRequest = false;

      expect(
        service.requestPermissions,
        throwsA(isA<HealthDataException>()),
      );
    });

    test('requestPermissions completes quietly when granted', () async {
      source.grantRequest = false;
      source.authorized = false;
      await expectLater(
        service.requestPermissions(),
        throwsA(isA<HealthDataException>()),
      );

      source.grantRequest = true;
      await service.requestPermissions();
      expect(await service.isAuthorized(), isTrue);
    });
  });

  group('deduplication', () {
    test('skips a glucose sample whose externalId is already stored', () async {
      source.samples = [glucose(externalId: 'HK-1')];
      final first = await service.importSince(since);
      expect(first.glucoseImported, 1);
      expect(first.duplicatesSkipped, 0);

      // The same sample comes back on the next read — Apple Health returns
      // overlapping windows, so this is the normal case, not an edge case.
      final second = await service.importSince(since);
      expect(second.glucoseImported, 0);
      expect(second.duplicatesSkipped, 1);
      expect(await db.glucoseDao.getAll(), hasLength(1));
    });

    test('skips a health sample whose externalId is already stored', () async {
      source.samples = [
        HealthSampleDto(
          kind: HealthSampleKind.steps,
          startAt: measuredAt,
          endAt: measuredAt.add(const Duration(hours: 1)),
          value: 1200,
          unit: 'COUNT',
          externalId: 'HK-steps',
        ),
      ];
      await service.importSince(since);
      final second = await service.importSince(since);

      expect(second.samplesImported, 0);
      expect(second.duplicatesSkipped, 1);
      expect(await db.healthSampleDao.getAll(), hasLength(1));
    });

    test('imports samples without an externalId rather than dropping them',
        () async {
      source.samples = [glucose(), glucose(value: 101)];
      final result = await service.importSince(since);

      expect(result.glucoseImported, 2);
      expect(result.duplicatesSkipped, 0);
      expect(await db.glucoseDao.getAll(), hasLength(2));
    });
  });

  group('partial authorization', () {
    test('imports what was granted and skips what was withheld', () async {
      // The user granted glucose only, so the source returns glucose alone.
      source.samples = [glucose(externalId: 'HK-1')];

      final result = await service.importSince(since);

      expect(result.glucoseImported, 1);
      expect(result.samplesImported, 0);
      expect(await db.healthSampleDao.getAll(), isEmpty);
      // Every kind is still asked for — the platform decides what it returns.
      expect(source.lastRequestedKinds, HealthSampleKind.values);
    });

    test('an empty read is a success, not a failure', () async {
      final result = await service.importSince(since);

      expect(result.totalImported, 0);
      expect(result.duplicatesSkipped, 0);
    });
  });

  group('routing and mapping', () {
    test('glucose goes to the glucose table tagged as healthKit', () async {
      source.samples = [glucose(externalId: 'HK-1', value: 132)];
      await service.importSince(since);

      final row = (await db.glucoseDao.getAll()).single;
      expect(row.valueMgDl, 132);
      // Drift stores DateTime as unix seconds and hands it back in local
      // time, so compare the instant rather than the isUtc flag.
      expect(row.measuredAt.toUtc(), measuredAt);
      expect(row.source, GlucoseSource.healthKit);
      expect(row.externalId, 'HK-1');
      expect(row.mealContext, null);
    });

    test('the other three kinds go to the health sample table', () async {
      source.samples = [
        HealthSampleDto(
          kind: HealthSampleKind.steps,
          startAt: measuredAt,
          value: 900,
          unit: 'COUNT',
          externalId: 'HK-a',
        ),
        HealthSampleDto(
          kind: HealthSampleKind.activeEnergy,
          startAt: measuredAt,
          value: 210,
          unit: 'KILOCALORIE',
          externalId: 'HK-b',
        ),
        HealthSampleDto(
          kind: HealthSampleKind.sleep,
          startAt: measuredAt,
          endAt: measuredAt.add(const Duration(hours: 7)),
          value: 420,
          unit: 'MINUTE',
          externalId: 'HK-c',
        ),
      ];
      final result = await service.importSince(since);

      expect(result.samplesImported, 3);
      final types = (await db.healthSampleDao.getAll())
          .map((s) => s.type)
          .toSet();
      expect(types, {
        HealthSampleType.steps,
        HealthSampleType.activeEnergy,
        HealthSampleType.sleep,
      });
    });

    test('workout metadata is stored as JSON', () async {
      source.samples = [
        HealthSampleDto(
          kind: HealthSampleKind.workout,
          startAt: measuredAt,
          endAt: measuredAt.add(const Duration(minutes: 45)),
          value: 45,
          unit: 'min',
          externalId: 'HK-w',
          metadata: const {'activityType': 'RUNNING'},
        ),
      ];
      await service.importSince(since);

      final row = (await db.healthSampleDao.getAll()).single;
      expect(row.type, HealthSampleType.workout);
      expect(jsonDecode(row.metadata!), {'activityType': 'RUNNING'});
    });
  });

  group('import window', () {
    test('first run reads back exactly the initial lookback', () async {
      final before = DateTime.now().subtract(HealthImportService.initialLookback);
      await service.import();
      final after = DateTime.now().subtract(HealthImportService.initialLookback);

      expect(source.lastSince!.isBefore(before.subtract(const Duration(seconds: 5))), isFalse);
      expect(source.lastSince!.isAfter(after.add(const Duration(seconds: 5))), isFalse);
    });

    test('a successful run records the marker and the next run resumes from it',
        () async {
      await service.import();

      final prefs = await SharedPreferences.getInstance();
      final marker = prefs.getString(AppConstants.prefKeyLastHealthImport);
      expect(marker, isNotNull);

      await service.import();
      expect(source.lastSince, DateTime.parse(marker!));
    });

    test('a failed run leaves the marker untouched so no window is lost',
        () async {
      await service.import();
      final prefs = await SharedPreferences.getInstance();
      final marker = prefs.getString(AppConstants.prefKeyLastHealthImport);

      source.authorized = false;
      await expectLater(service.import(), throwsA(isA<HealthDataException>()));

      expect(
        prefs.getString(AppConstants.prefKeyLastHealthImport),
        marker,
      );
    });

    test('an unparseable marker falls back to the lookback window', () async {
      SharedPreferences.setMockInitialValues({
        AppConstants.prefKeyLastHealthImport: 'not-a-timestamp',
      });

      await service.import();

      expect(source.lastSince, isNotNull);
      expect(
        DateTime.now().difference(source.lastSince!).inDays,
        HealthImportService.initialLookback.inDays,
      );
    });
  });

  test('disconnect releases access and clears the marker', () async {
    await service.import();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(AppConstants.prefKeyLastHealthImport), isNotNull);

    await service.disconnect();

    expect(source.disconnectCount, 1);
    expect(prefs.getString(AppConstants.prefKeyLastHealthImport), null);
  });
}
