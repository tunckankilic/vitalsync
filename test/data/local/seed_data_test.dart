import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalsync/core/di/injection_container.dart';
import 'package:vitalsync/data/local/database.dart';

/// Guards the seed-catalogue regression: the preset exercise library and
/// default workout templates must survive a sign-out wipe / reinstall, which
/// [seedDefaultDataIfEmpty] restores on the next login (see AuthNotifier) as
/// well as at cold start.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('seedDefaultDataIfEmpty', () {
    test('seeds the default exercise catalogue and templates when empty', () async {
      expect(await db.exerciseDao.getAll(), isEmpty);

      await seedDefaultDataIfEmpty(db);

      expect((await db.exerciseDao.getAll()).length, greaterThan(40));
      expect(await db.workoutTemplateDao.getAll(), isNotEmpty);
    });

    test('restores the catalogue after a sign-out / reinstall wipe', () async {
      await seedDefaultDataIfEmpty(db);
      final seededCount = (await db.exerciseDao.getAll()).length;
      expect(seededCount, greaterThan(0));

      // Mirror clearLocalDataOnSignOut(): the whole local DB is wiped.
      await db.deleteAllData();
      expect(await db.exerciseDao.getAll(), isEmpty);
      expect(await db.workoutTemplateDao.getAll(), isEmpty);

      // The returning user's post-login guard re-seeds the empty catalogue.
      await seedDefaultDataIfEmpty(db);
      expect((await db.exerciseDao.getAll()).length, seededCount);
      expect(await db.workoutTemplateDao.getAll(), isNotEmpty);
    });

    test('is a no-op when exercises already exist (never duplicates)', () async {
      await seedDefaultDataIfEmpty(db);
      final firstCount = (await db.exerciseDao.getAll()).length;
      final firstTemplateCount = (await db.workoutTemplateDao.getAll()).length;

      // A second guard run (e.g. a later login) must not duplicate anything.
      await seedDefaultDataIfEmpty(db);

      expect((await db.exerciseDao.getAll()).length, firstCount);
      expect((await db.workoutTemplateDao.getAll()).length, firstTemplateCount);
    });
  });
}
