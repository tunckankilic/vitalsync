import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalsync/data/local/database.dart';

import '../../drift_schemas/schema.dart';
import '../../drift_schemas/schema_v2.dart' as v2;

/// Guards the v2 → v3 migration: a data-only fix to the three cross-module
/// achievement descriptions.
///
/// Seeding runs solely on an empty database, so an existing install keeps
/// whatever text it was seeded with — which is why this correction has to
/// travel as a migration. The risk it carries is that an achievement a user
/// has already earned loses its unlock, so that is what these tests pin down.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  /// Inserts an achievement through the v2 schema, as a shipped install
  /// would hold it.
  Future<void> insertAtV2(
    v2.DatabaseAtV2 db, {
    required String type,
    required String title,
    required String description,
    required int requirement,
    required String iconName,
    DateTime? unlockedAt,
  }) async {
    await db
        .into(db.achievements)
        .insert(
          RawValuesInsertable({
            'type': Variable<String>(type),
            'title': Variable<String>(title),
            'description': Variable<String>(description),
            'requirement': Variable<int>(requirement),
            'icon_name': Variable<String>(iconName),
            if (unlockedAt != null)
              'unlocked_at': Variable<int>(
                unlockedAt.millisecondsSinceEpoch ~/ 1000,
              ),
          }),
        );
  }

  Future<Map<String, AchievementData>> byIconName(AppDatabase db) async {
    final rows = await db.select(db.achievements).get();
    return {for (final row in rows) row.iconName: row};
  }

  group('schema migration v2 → v3', () {
    test('produces the expected v3 schema', () async {
      final connection = await verifier.startAt(2);
      final db = AppDatabase(connection);
      addTearDown(db.close);

      await verifier.migrateAndValidate(db, 3);
    });

    test('rewrites the three cross-module descriptions', () async {
      final schema = await verifier.schemaAt(2);

      final oldDb = v2.DatabaseAtV2(schema.newConnection());
      await insertAtV2(
        oldDb,
        type: 'consistency',
        title: 'Balance Master',
        description:
            'Achieve 100% medication compliance and 4 workouts in the '
            'same week',
        requirement: 1,
        iconName: 'cross_balance_master',
      );
      await insertAtV2(
        oldDb,
        type: 'consistency',
        title: 'Synced Up',
        description:
            'Maintain both medication compliance and workout streak for '
            '30 days',
        requirement: 30,
        iconName: 'cross_synced_up',
      );
      await insertAtV2(
        oldDb,
        type: 'consistency',
        title: 'Wellness Warrior',
        description: 'Complete 50 workouts with 90%+ medication compliance',
        requirement: 50,
        iconName: 'cross_wellness_warrior',
      );
      await oldDb.close();

      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 3);

      final rows = await byIconName(db);
      expect(
        rows['cross_balance_master']!.description,
        'Keep 90%+ medication compliance this week and a 1-day workout '
        'streak',
      );
      expect(
        rows['cross_synced_up']!.description,
        'Keep 90%+ medication compliance this week and a 30-day workout '
        'streak',
      );
      expect(
        rows['cross_wellness_warrior']!.description,
        'Keep 90%+ medication compliance this week and a 50-day workout '
        'streak',
      );

      // The unlock rule itself did not change, so neither did the number
      // each description now quotes.
      expect(rows['cross_balance_master']!.requirement, 1);
      expect(rows['cross_synced_up']!.requirement, 30);
      expect(rows['cross_wellness_warrior']!.requirement, 50);
    });

    test('keeps an already earned achievement unlocked', () async {
      final schema = await verifier.schemaAt(2);
      final unlockedAt = DateTime.utc(2026, 8, 1);

      final oldDb = v2.DatabaseAtV2(schema.newConnection());
      await insertAtV2(
        oldDb,
        type: 'consistency',
        title: 'Synced Up',
        description:
            'Maintain both medication compliance and workout streak for '
            '30 days',
        requirement: 30,
        iconName: 'cross_synced_up',
        unlockedAt: unlockedAt,
      );
      await oldDb.close();

      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 3);

      final row = (await byIconName(db))['cross_synced_up']!;
      expect(row.description, contains('30-day workout streak'));
      expect(row.unlockedAt, unlockedAt.toLocal());
    });

    test('leaves achievements outside the cross-module set alone', () async {
      final schema = await verifier.schemaAt(2);

      final oldDb = v2.DatabaseAtV2(schema.newConnection());
      await insertAtV2(
        oldDb,
        type: 'streak',
        title: 'Week Warrior',
        description: 'Complete workouts on 7 consecutive days',
        requirement: 7,
        iconName: 'week_warrior',
      );
      await oldDb.close();

      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 3);

      final row = (await byIconName(db))['week_warrior']!;
      expect(row.description, 'Complete workouts on 7 consecutive days');
    });

    test('is idempotent over the corrected text', () async {
      final schema = await verifier.schemaAt(2);
      const corrected =
          'Keep 90%+ medication compliance this week and a 50-day workout '
          'streak';

      // A row that somehow already carries the new wording must not be
      // matched by the guard and rewritten a second time.
      final oldDb = v2.DatabaseAtV2(schema.newConnection());
      await insertAtV2(
        oldDb,
        type: 'consistency',
        title: 'Wellness Warrior',
        description: corrected,
        requirement: 50,
        iconName: 'cross_wellness_warrior',
      );
      await oldDb.close();

      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 3);

      final row = (await byIconName(db))['cross_wellness_warrior']!;
      expect(row.description, corrected);
    });
  });
}
