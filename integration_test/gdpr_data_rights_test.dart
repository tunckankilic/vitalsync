// GDPR export and erasure, over the real Drift schema.
//
// Both of these are switch-free list-walking code in database.dart: a table
// that nobody remembered to add is simply absent, and absence is exactly what
// the two operations look like when they succeed. So a missed table means
// export quietly omits the user's data, or "delete my account" quietly leaves
// health records behind — with no error, no log line and no failing unit test,
// because the unit tests mock the tables they know about.
//
// These run over the real schema instead, so a table added tomorrow and
// forgotten in either method fails here.
//
// Run with: flutter test integration_test

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:vitalsync/core/enums/health_sample_type.dart';

import 'harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(tz_data.initializeTimeZones);

  late TestApp app;

  tearDown(() async => app.dispose());

  /// Writes one row into each of the four collections 2.0 introduced.
  Future<void> seedMeasurementLayer() async {
    final now = DateTime.now();

    await app.mealRepository.insert(mealNamed('Mercimek', at: now));
    await app.glucoseRepository.insert(
      manualReadingAt(now.add(const Duration(minutes: 30)), value: 118),
    );
    await app.healthSampleRepository.insert(
      importedSampleAt(
        now,
        type: HealthSampleType.steps,
        value: 5100,
        unit: 'count',
        externalId: 'hk-steps-export',
      ),
    );
    await app.calibrationMetricRepository.insert(
      calibrationMetricFor(DateTime(now.year, now.month, now.day)),
    );
  }

  group('data export', () {
    testWidgets('carries every collection the measurement layer writes', (
      tester,
    ) async {
      app = buildTestApp();
      await seedMeasurementLayer();

      final export = await app.db.exportAllData();
      final health = export['health']! as Map<String, dynamic>;

      // A table missing from exportAllData is a right-to-portability gap, and
      // it looks identical to "the user has no data of that kind".
      expect(health['meals'], hasLength(1));
      expect(health['glucose_readings'], hasLength(1));
      expect(health['health_samples'], hasLength(1));
      expect(export['calibration_metrics'], hasLength(1));
    });

    testWidgets('stamps the schema version it was taken at', (tester) async {
      app = buildTestApp();

      final export = await app.db.exportAllData();

      // Without this an export cannot be read back once the schema moves on.
      expect(export['database_version'], app.db.schemaVersion);
      expect(export['export_timestamp'], isA<String>());
    });

    testWidgets('the calibration rows carry counts and nothing else', (
      tester,
    ) async {
      app = buildTestApp();
      await seedMeasurementLayer();

      final export = await app.db.exportAllData();
      final metrics = (export['calibration_metrics']! as List).single
          .toString();

      // Opt-in telemetry is tallies only. A measurement, a meal name or a note
      // appearing here would mean health data had leaked into the counters —
      // the boundary CONTEXT-2.0.md draws around this table.
      expect(metrics, isNot(contains('118')));
      expect(metrics, isNot(contains('Mercimek')));
      expect(metrics, contains('1.1.0'));
    });
  });

  group('erasure', () {
    testWidgets('clears every collection the measurement layer writes', (
      tester,
    ) async {
      app = buildTestApp();
      await seedMeasurementLayer();

      // Guard the guard: if the seed silently wrote nothing, an empty result
      // after the delete would prove nothing at all.
      expect(await app.mealRepository.getAll(), isNotEmpty);
      expect(await app.glucoseRepository.getAll(), isNotEmpty);
      expect(await app.healthSampleRepository.getAll(), isNotEmpty);
      expect(await app.calibrationMetricRepository.getAll(), isNotEmpty);

      await app.db.deleteAllData();

      expect(await app.mealRepository.getAll(), isEmpty);
      expect(await app.glucoseRepository.getAll(), isEmpty);
      expect(await app.healthSampleRepository.getAll(), isEmpty);
      expect(await app.calibrationMetricRepository.getAll(), isEmpty);
    });

    testWidgets('drains the pending sync queue with the data', (tester) async {
      app = buildTestApp();
      await seedMeasurementLayer();

      // Meals, manual readings and calibration rows all queue a push.
      expect(await app.pendingSyncItems(), isNotEmpty);

      await app.db.deleteAllData();

      // A queue entry that outlived its row would re-push deleted health data
      // on the next sync.
      expect(await app.pendingSyncItems(), isEmpty);
    });

    testWidgets('an export taken afterwards is empty', (tester) async {
      app = buildTestApp();
      await seedMeasurementLayer();

      await app.db.deleteAllData();

      final export = await app.db.exportAllData();
      final health = export['health']! as Map<String, dynamic>;

      expect(health['meals'], isEmpty);
      expect(health['glucose_readings'], isEmpty);
      expect(health['health_samples'], isEmpty);
      expect(export['calibration_metrics'], isEmpty);
      expect(export['user_profile'], isNull);
    });
  });
}
