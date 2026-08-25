import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalsync/data/local/database.dart';

import '../../drift_schemas/schema.dart';
import '../../drift_schemas/schema_v1.dart' as v1;

/// Guards the v1 → v2 schema migration: the 2.0 measurement layer adds four
/// tables and must not disturb anything that was already stored. A user
/// upgrading from the App Store release carries v1 data on disk, so a
/// migration that drops or rewrites an existing table would silently destroy
/// health records.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('schema migration v1 → v2', () {
    test('produces the expected v2 schema', () async {
      final connection = await verifier.startAt(1);
      final db = AppDatabase(connection);
      addTearDown(db.close);

      await verifier.migrateAndValidate(db, 2);
    });

    test('preserves existing v1 data', () async {
      final schema = await verifier.schemaAt(1);

      // Write a row through the v1 schema, exactly as the shipped release
      // would have stored it.
      final oldDb = v1.DatabaseAtV1(schema.newConnection());
      await oldDb
          .into(oldDb.symptoms)
          .insert(
            RawValuesInsertable({
              'name': Variable<String>('Headache'),
              'severity': Variable<int>(3),
              'date': Variable<int>(
                DateTime.utc(2026, 8, 1).millisecondsSinceEpoch ~/ 1000,
              ),
              'notes': Variable<String>('After a long day'),
              'tags': Variable<String>('["chronic"]'),
            }),
          );
      await oldDb.close();

      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 2);

      final survivors = await db.symptomDao.getAll();
      expect(survivors, hasLength(1));
      expect(survivors.single.name, 'Headache');
      expect(survivors.single.severity, 3);
      expect(survivors.single.tags, '["chronic"]');
    });

    test('creates the four 2.0 tables empty', () async {
      final schema = await verifier.schemaAt(1);
      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 2);

      expect(await db.glucoseDao.getAll(), isEmpty);
      expect(await db.mealDao.getAll(), isEmpty);
      expect(await db.healthSampleDao.getAll(), isEmpty);
      expect(await db.calibrationMetricDao.getAll(), isEmpty);
    });
  });
}
