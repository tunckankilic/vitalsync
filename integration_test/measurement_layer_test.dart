// End-to-end coverage of the 2.0 measurement layer.
//
// Unit tests pin each piece against mocks. These drive the real screens over
// the real Drift schema and assert what the next layer actually sees: the row
// in the database, the entry in the sync queue, the notification that would
// have been scheduled. The seams those layers meet at are where every defect
// in this module has come from so far.
//
// Run with: flutter test integration_test

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:vitalsync/core/constants/app_constants.dart';
import 'package:vitalsync/core/enums/glucose_source.dart';
import 'package:vitalsync/core/enums/health_sample_type.dart';
import 'package:vitalsync/core/enums/sync_enums.dart';
import 'package:vitalsync/core/notifications/notification_service.dart';
import 'package:vitalsync/features/health/presentation/screens/add_glucose_reading_screen.dart';
import 'package:vitalsync/features/health/presentation/screens/add_meal_screen.dart';
import 'package:vitalsync/features/health/presentation/screens/glucose_list_screen.dart';
import 'package:vitalsync/features/health/presentation/screens/meal_list_screen.dart';

import 'harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // The reminder scheduler resolves tz.local, which throws until the IANA
  // database is loaded.
  setUpAll(tz_data.initializeTimeZones);

  late TestApp app;

  tearDown(() async => app.dispose());

  Future<void> enterText(WidgetTester tester, Finder field, String text) async {
    await tester.enterText(field, text);
    await tester.pumpAndSettle();
  }

  Future<void> tapSave(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
  }

  group('logging a meal', () {
    testWidgets('reaches the database, the sync queue and the reminder', (
      tester,
    ) async {
      app = buildTestApp();
      await pumpScreen(tester, app, const AddMealScreen());

      await enterText(tester, find.byType(TextFormField).first, 'Oatmeal');
      await tapSave(tester);

      // 1. The row exists, with what was typed.
      final meals = await app.mealRepository.getAll();
      expect(meals, hasLength(1));
      expect(meals.single.name, 'Oatmeal');

      // 2. It is queued for the cloud. Meals are the user's own input and
      //    cannot be re-derived, so they push in full.
      final queued = await app.pendingSyncItems();
      expect(queued.where((i) => i.targetTable == 'meals'), hasLength(1));
      expect(queued.single.operation, SyncOperation.insert);

      // 3. A measurement reminder is armed for two hours later.
      expect(app.notifications.scheduled, hasLength(1));
      final reminder = app.notifications.scheduled.single;
      expect(
        reminder.at.difference(meals.single.eatenAt).inHours,
        AppConstants.postMealReminderDelayHours,
      );
      expect(reminder.id, greaterThanOrEqualTo(kPostMealReminderIdOffset));
    });

    testWidgets('the reminder text asks for a measurement and nothing more', (
      tester,
    ) async {
      app = buildTestApp();
      await pumpScreen(tester, app, const AddMealScreen());

      await enterText(tester, find.byType(TextFormField).first, 'Pasta');
      await tapSave(tester);

      final body = app.notifications.scheduled.single.body!;

      // The meal name must not travel to the lock screen, and the text must
      // carry no interpretation, prediction or advice.
      expect(body, isNot(contains('Pasta')));
      for (final forbidden in const [
        'high',
        'low',
        'spike',
        'peak',
        'normal',
        'walk',
        'exercise',
      ]) {
        expect(body.toLowerCase(), isNot(contains(forbidden)));
      }
    });

    testWidgets('schedules nothing while the reminder setting is off', (
      tester,
    ) async {
      app = buildTestApp(remindersEnabled: false);
      await pumpScreen(tester, app, const AddMealScreen());

      await enterText(tester, find.byType(TextFormField).first, 'Salad');
      await tapSave(tester);

      // The meal is still recorded — only the reminder is suppressed.
      expect(await app.mealRepository.getAll(), hasLength(1));
      expect(app.notifications.scheduled, isEmpty);
    });

    testWidgets('an empty name is rejected and nothing is written', (
      tester,
    ) async {
      app = buildTestApp();
      await pumpScreen(tester, app, const AddMealScreen());

      await tapSave(tester);

      expect(await app.mealRepository.getAll(), isEmpty);
      expect(await app.pendingSyncItems(), isEmpty);
      expect(app.notifications.scheduled, isEmpty);
    });
  });

  group('logging a measurement', () {
    testWidgets('stores mg/dL, marks it manual, and queues it', (tester) async {
      app = buildTestApp();
      await pumpScreen(tester, app, const AddGlucoseReadingScreen());

      await enterText(tester, find.byType(TextFormField).first, '112');
      await tapSave(tester);

      final readings = await app.glucoseRepository.getAll();
      expect(readings, hasLength(1));
      expect(readings.single.valueMgDl, 112);
      expect(readings.single.source, GlucoseSource.manual);

      final queued = await app.pendingSyncItems();
      expect(
        queued.where((i) => i.targetTable == 'glucose_readings'),
        hasLength(1),
      );
    });

    testWidgets('a mmol/L entry is converted before it is stored', (
      tester,
    ) async {
      app = buildTestApp();
      await pumpScreen(tester, app, const AddGlucoseReadingScreen());

      await enterText(tester, find.byType(TextFormField).first, '6.2');
      await tester.tap(find.text('mmol/L'));
      await tester.pumpAndSettle();
      await tapSave(tester);

      // The database is always mg/dL, whatever unit was typed.
      final stored = (await app.glucoseRepository.getAll()).single;
      expect(stored.valueMgDl, closeTo(111.7, 0.5));
    });
  });

  group('the lists show what was written', () {
    testWidgets('a logged meal appears with its coverage verdict', (
      tester,
    ) async {
      app = buildTestApp();
      await pumpScreen(tester, app, const AddMealScreen());
      await enterText(tester, find.byType(TextFormField).first, 'Risotto');
      await tapSave(tester);

      await pumpScreen(tester, app, const MealListScreen());

      expect(find.text('Risotto'), findsOneWidget);
      // No readings around it yet, so it reports as uncovered — a statement
      // about the recording, never about the meal.
      expect(find.textContaining('No measurement data'), findsOneWidget);
    });

    testWidgets('a logged reading appears in the list', (tester) async {
      app = buildTestApp();
      await pumpScreen(tester, app, const AddGlucoseReadingScreen());
      await enterText(tester, find.byType(TextFormField).first, '99');
      await tapSave(tester);

      await pumpScreen(tester, app, const GlucoseListScreen());

      expect(find.text('99'), findsOneWidget);
    });
  });

  group('deleting', () {
    testWidgets('a meal removes the row, queues a delete and cancels the '
        'reminder', (tester) async {
      app = buildTestApp();
      await pumpScreen(tester, app, const AddMealScreen());
      await enterText(tester, find.byType(TextFormField).first, 'Toast');
      await tapSave(tester);

      final mealId = (await app.mealRepository.getAll()).single.id;
      app.notifications.cancelled.clear();

      await pumpScreen(tester, app, const MealListScreen());
      await tester.drag(find.text('Toast'), const Offset(-500, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(await app.mealRepository.getAll(), isEmpty);

      final deletes = (await app.pendingSyncItems())
          .where((i) => i.operation == SyncOperation.delete)
          .toList();
      expect(deletes.map((d) => d.targetTable), contains('meals'));

      // The pending reminder must go with the meal.
      expect(
        app.notifications.cancelled,
        contains(kPostMealReminderIdOffset + mealId),
      );
    });

    testWidgets('a cancelled confirmation keeps the meal', (tester) async {
      app = buildTestApp();
      await pumpScreen(tester, app, const AddMealScreen());
      await enterText(tester, find.byType(TextFormField).first, 'Soup');
      await tapSave(tester);

      await pumpScreen(tester, app, const MealListScreen());
      await tester.drag(find.text('Soup'), const Offset(-500, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(await app.mealRepository.getAll(), hasLength(1));
    });
  });

  group('the 2.0 boundary holds end to end', () {
    testWidgets('a meal with readings around it reports as covered, with no '
        'verdict on the readings', (tester) async {
      app = buildTestApp();

      // Three readings inside the post-meal window is what the coverage
      // service asks for.
      await pumpScreen(tester, app, const AddMealScreen());
      await enterText(tester, find.byType(TextFormField).first, 'Lunch');
      await tapSave(tester);

      final meal = (await app.mealRepository.getAll()).single;
      for (var i = 0; i < 3; i++) {
        await app.glucoseRepository.insert(
          manualReadingAt(
            meal.eatenAt.add(Duration(minutes: 20 * (i + 1))),
            value: 120 + i * 10,
          ),
        );
      }

      await pumpScreen(tester, app, const MealListScreen());

      expect(find.textContaining('Measurement data'), findsOneWidget);
      // The values themselves are never shown on the meal row, and nothing
      // rates them.
      expect(find.textContaining('120'), findsNothing);
      expect(find.textContaining('high'), findsNothing);
      expect(find.textContaining('normal'), findsNothing);
    });

    testWidgets('a HealthKit-sourced reading never enters the sync queue', (
      tester,
    ) async {
      app = buildTestApp();

      await app.glucoseRepository.insert(
        manualReadingAt(
          DateTime.now(),
          value: 105,
        ).copyWith(source: GlucoseSource.healthKit, externalId: 'hk-1'),
      );

      // A CGM writes hundreds of readings a day and every one is
      // re-importable, so pushing them would multiply write cost for nothing.
      expect(
        (await app.pendingSyncItems()).where(
          (i) => i.targetTable == 'glucose_readings',
        ),
        isEmpty,
      );
      // It is still stored and listed locally.
      expect(await app.glucoseRepository.getAll(), hasLength(1));
    });

    testWidgets('imported activity and sleep samples never enter the queue', (
      tester,
    ) async {
      app = buildTestApp();
      final now = DateTime.now();

      // Every type the Apple Health import can write, other than glucose.
      await app.healthSampleRepository.insert(
        importedSampleAt(
          now,
          type: HealthSampleType.steps,
          value: 4200,
          unit: 'count',
          externalId: 'hk-steps-1',
        ),
      );
      await app.healthSampleRepository.insert(
        importedSampleAt(
          now,
          type: HealthSampleType.activeEnergy,
          value: 310,
          unit: 'kcal',
          externalId: 'hk-energy-1',
        ),
      );
      await app.healthSampleRepository.insert(
        importedSampleAt(
          now,
          type: HealthSampleType.sleep,
          value: 7.5,
          unit: 'hr',
          externalId: 'hk-sleep-1',
        ),
      );

      // health_samples is deliberately absent from SyncService.tablesToSync:
      // the platform health store can re-supply all of it on a new device, and
      // uploading it would put the Health app's contents in the cloud without
      // a consent that covers it.
      expect(await app.pendingSyncItems(), isEmpty);
      expect(await app.healthSampleRepository.getAll(), hasLength(3));
    });
  });

  group('the measurement screens in Turkish', () {
    // Section 1B of the RC runbook says these five screens have never had a
    // tri-lingual pass. A missing .arb key falls back to English rather than
    // failing the build, so rendering them is the only way to see it.

    Future<void> saveInTurkish(WidgetTester tester) async {
      await tester.tap(find.widgetWithText(FilledButton, 'Kaydet'));
      await tester.pumpAndSettle();
    }

    testWidgets('the meal form saves the same row it does in English', (
      tester,
    ) async {
      app = buildTestApp();
      await pumpScreen(
        tester,
        app,
        const AddMealScreen(),
        locale: const Locale('tr'),
      );

      expect(find.text('Öğün Ekle'), findsOneWidget);
      expect(find.text('Save'), findsNothing);

      await enterText(tester, find.byType(TextFormField).first, 'Mercimek');
      await saveInTurkish(tester);

      // Language changes the labels, never the data.
      final meals = await app.mealRepository.getAll();
      expect(meals, hasLength(1));
      expect(meals.single.name, 'Mercimek');
      expect(
        (await app.pendingSyncItems()).where((i) => i.targetTable == 'meals'),
        hasLength(1),
      );
    });

    testWidgets('the coverage badge is translated and still states a fact', (
      tester,
    ) async {
      app = buildTestApp();
      await pumpScreen(
        tester,
        app,
        const AddMealScreen(),
        locale: const Locale('tr'),
      );
      await enterText(tester, find.byType(TextFormField).first, 'Menemen');
      await saveInTurkish(tester);

      await pumpScreen(
        tester,
        app,
        const MealListScreen(),
        locale: const Locale('tr'),
      );

      expect(find.text('Menemen'), findsOneWidget);
      expect(find.textContaining('Ölçüm verisi yok'), findsOneWidget);
      expect(find.textContaining('No measurement data'), findsNothing);
    });

    testWidgets('the reminder body is Turkish and still says nothing about '
        'the reading', (tester) async {
      // The reminder text is composed with no widget in scope, so it comes
      // from the injected localization seam rather than a BuildContext. That
      // seam is the whole reason a scheduled notification can arrive in
      // English while the app is in Turkish.
      app = buildTestApp(notificationLocale: const Locale('tr'));
      await pumpScreen(
        tester,
        app,
        const AddMealScreen(),
        locale: const Locale('tr'),
      );
      await enterText(tester, find.byType(TextFormField).first, 'Pilav');
      await saveInTurkish(tester);

      final body = app.notifications.scheduled.single.body!;
      expect(body, contains('ölçüm'));
      expect(body, isNot(contains('reading')));

      // The boundary is a property of the text in every language, not of the
      // English wording.
      expect(body, isNot(contains('Pilav')));
      for (final forbidden in const [
        'yüksek',
        'düşük',
        'normal',
        'yürüyüş',
        'egzersiz',
      ]) {
        expect(body.toLowerCase(), isNot(contains(forbidden)));
      }
    });
  });
}
