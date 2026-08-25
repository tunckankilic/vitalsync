// Widget tests for the manual glucose entry screen.
//
// The screen is the only place a reading is typed by hand, so what is
// pinned down here is the storage contract: whatever unit the user picks,
// the row that reaches the repository is in mg/dL, sourced `manual` and
// queued as pending.
//
// Unlike the other screen tests this one installs a real (tiny) GoRouter:
// the save path ends in `context.pop()`, which needs a router in the tree.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vitalsync/core/enums/glucose_source.dart';
import 'package:vitalsync/core/enums/glucose_unit.dart';
import 'package:vitalsync/core/enums/sync_status.dart';
import 'package:vitalsync/core/l10n/app_localizations.dart';
import 'package:vitalsync/domain/entities/health/glucose_reading.dart';
import 'package:vitalsync/domain/repositories/health/glucose_repository.dart';
import 'package:vitalsync/features/health/presentation/providers/glucose_provider.dart';
import 'package:vitalsync/features/health/presentation/screens/add_glucose_reading_screen.dart';

class _MockGlucoseRepository extends Mock implements GlucoseRepository {}

void main() {
  late _MockGlucoseRepository repository;

  setUpAll(() {
    registerFallbackValue(
      GlucoseReading(
        id: 0,
        valueMgDl: 0,
        measuredAt: DateTime(2026),
        source: GlucoseSource.manual,
        lastModifiedAt: DateTime(2026),
        createdAt: DateTime(2026),
      ),
    );
  });

  setUp(() {
    repository = _MockGlucoseRepository();
    when(() => repository.insert(any())).thenAnswer((_) async => 1);
  });

  /// Pumps the screen on a route that can be popped, with a tall surface so
  /// the whole form (including the save button) is laid out.
  Future<void> pumpAddGlucose(
    WidgetTester tester, {
    DateTime? initialMeasuredAt,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1000, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(
      initialLocation: '/add',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SizedBox.shrink()),
        GoRoute(
          path: '/add',
          builder: (_, _) =>
              AddGlucoseReadingScreen(initialMeasuredAt: initialMeasuredAt),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          glucoseRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // Not `find.byIcon(Icons.check)`: SegmentedButton draws a check on the
  // selected segment, so that finder is ambiguous.
  final saveButton = find.widgetWithText(FilledButton, 'Save');

  Future<void> tapSave(WidgetTester tester) async {
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
  }

  Future<void> enterValueAndSave(WidgetTester tester, String value) async {
    await tester.enterText(find.byType(TextFormField).first, value);
    await tapSave(tester);
  }

  Future<void> selectMmolPerL(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byType(SegmentedButton<GlucoseUnit>),
        matching: find.text('mmol/L'),
      ),
    );
    await tester.pumpAndSettle();
  }

  GlucoseReading capturedReading() {
    return verify(() => repository.insert(captureAny())).captured.single
        as GlucoseReading;
  }

  testWidgets('renders the value field and both units', (tester) async {
    await pumpAddGlucose(tester);

    expect(find.text('Value'), findsOneWidget);
    expect(find.text('mg/dL'), findsWidgets);
    expect(find.text('mmol/L'), findsOneWidget);
  });

  testWidgets('an empty value is rejected and nothing is stored', (
    tester,
  ) async {
    await pumpAddGlucose(tester);

    await tapSave(tester);

    expect(find.text('Enter a value'), findsOneWidget);
    verifyNever(() => repository.insert(any()));
  });

  testWidgets('a non-numeric value is rejected and nothing is stored', (
    tester,
  ) async {
    await pumpAddGlucose(tester);

    // The input formatter already blocks letters, so the reachable bad
    // input is a bare separator.
    await enterValueAndSave(tester, '.');

    expect(find.text('Enter a valid number'), findsOneWidget);
    verifyNever(() => repository.insert(any()));
  });

  testWidgets('a mg/dL value is stored unchanged', (tester) async {
    await pumpAddGlucose(tester);

    await enterValueAndSave(tester, '112');

    expect(capturedReading().valueMgDl, 112);
  });

  testWidgets('a mmol/L value is converted to mg/dL before storage', (
    tester,
  ) async {
    await pumpAddGlucose(tester);
    await selectMmolPerL(tester);

    await enterValueAndSave(tester, '5.5');

    expect(capturedReading().valueMgDl, closeTo(99.1, 0.1));
  });

  testWidgets('a comma decimal separator is accepted', (tester) async {
    await pumpAddGlucose(tester);

    await enterValueAndSave(tester, '5,5');

    expect(capturedReading().valueMgDl, closeTo(5.5, 0.0001));
  });

  // The post-meal reminder opens this screen with the moment it fired, so the
  // user only has to type the value. Only the time is pre-filled.
  testWidgets('an initial measurement time is pre-filled and stored', (
    tester,
  ) async {
    final remindedAt = DateTime(2026, 3, 14, 9, 45);

    await pumpAddGlucose(tester, initialMeasuredAt: remindedAt);

    expect(find.text('Mar 14, 2026'), findsOneWidget);

    await enterValueAndSave(tester, '100');

    expect(capturedReading().measuredAt, remindedAt);
  });

  testWidgets('the stored reading is manual and pending sync', (tester) async {
    await pumpAddGlucose(tester);

    await enterValueAndSave(tester, '100');

    final reading = capturedReading();
    expect(reading.source, GlucoseSource.manual);
    expect(reading.syncStatus, SyncStatus.pending);
    // Nothing was imported, so there is no external identity to carry.
    expect(reading.externalId, isNull);
  });
}
