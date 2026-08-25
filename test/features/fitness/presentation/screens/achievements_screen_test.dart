import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalsync/core/enums/achievement_type.dart';
import 'package:vitalsync/core/l10n/app_localizations.dart';
import 'package:vitalsync/domain/entities/fitness/achievement.dart';
import 'package:vitalsync/features/fitness/presentation/providers/achievement_provider.dart';
import 'package:vitalsync/features/fitness/presentation/screens/achievements_screen.dart';

/// The achievements screen reads English rows out of the database and is
/// expected to translate them on the way to the card. Proving the extension
/// alone is not enough — the screen has to actually call it, and the failure
/// mode if it stops is invisible in English.
void main() {
  // Stored text is deliberately unlike any real copy, so seeing it on screen
  // means the row was rendered raw.
  const storedUnlockedTitle = 'STORED UNLOCKED TITLE';
  const storedUnlockedDesc = 'STORED UNLOCKED DESCRIPTION';
  const storedLockedTitle = 'STORED LOCKED TITLE';

  final unlocked = Achievement(
    id: 1,
    type: AchievementType.streak,
    title: storedUnlockedTitle,
    description: storedUnlockedDesc,
    requirement: 7,
    iconName: 'fitness_week_warrior',
    unlockedAt: DateTime.now(),
  );

  const locked = Achievement(
    id: 2,
    type: AchievementType.medicationCompliance,
    title: storedLockedTitle,
    description: 'STORED LOCKED DESCRIPTION',
    requirement: 30,
    iconName: 'health_hero',
  );

  const crossModule = Achievement(
    id: 3,
    type: AchievementType.consistency,
    title: 'STORED CROSS TITLE',
    description: 'STORED CROSS DESCRIPTION',
    requirement: 30,
    iconName: 'cross_synced_up',
  );

  Future<void> pumpScreen(WidgetTester tester, Locale locale) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          achievementsProvider.overrideWith(
            (ref) => Stream.value([unlocked, locked, crossModule]),
          ),
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AchievementsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders Turkish copy, not the stored English row', (
    tester,
  ) async {
    await pumpScreen(tester, const Locale('tr'));

    expect(find.text('Hafta Savaşçısı'), findsOneWidget);
    expect(find.text('7 günlük antrenman serisini sürdür'), findsOneWidget);
    // A locked achievement still shows its name; its requirement stays hidden.
    expect(find.text('Sağlık Kahramanı'), findsOneWidget);

    expect(find.text(storedUnlockedTitle), findsNothing);
    expect(find.text(storedUnlockedDesc), findsNothing);
    expect(find.text(storedLockedTitle), findsNothing);
  });

  testWidgets('renders German copy, not the stored English row', (
    tester,
  ) async {
    await pumpScreen(tester, const Locale('de'));

    expect(find.text('Wochenkrieger'), findsOneWidget);
    expect(find.text('Halte eine 7-tägige Workout-Serie'), findsOneWidget);
    expect(find.text('Gesundheitsheld'), findsOneWidget);

    expect(find.text(storedUnlockedTitle), findsNothing);
    expect(find.text(storedUnlockedDesc), findsNothing);
    expect(find.text(storedLockedTitle), findsNothing);
  });

  testWidgets('still renders the English copy for an English locale', (
    tester,
  ) async {
    await pumpScreen(tester, const Locale('en'));

    expect(find.text('Week Warrior'), findsOneWidget);
    expect(find.text('Maintain a 7-day workout streak'), findsOneWidget);
    expect(find.text(storedUnlockedTitle), findsNothing);
  });

  group('category filter', () {
    /// Taps a chip by its label, scrolling the chip row if it sits off-screen.
    Future<void> tapChip(WidgetTester tester, String label) async {
      final chip = find.widgetWithText(ChoiceChip, label);
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
    }

    testWidgets('offers a chip for every achievement type', (tester) async {
      await pumpScreen(tester, const Locale('en'));

      // Six types plus "All". Medication and Consistency were missing, which
      // left their achievements reachable only through "All".
      for (final label in [
        'All',
        'Streak',
        'Total Volume',
        'Workouts',
        'Personal Records',
        'Medication',
        'Consistency',
      ]) {
        expect(
          find.widgetWithText(ChoiceChip, label),
          findsOneWidget,
          reason: label,
        );
      }
    });

    testWidgets('filtering to Medication hides the other categories', (
      tester,
    ) async {
      await pumpScreen(tester, const Locale('en'));
      await tapChip(tester, 'Medication');

      expect(find.text('Health Hero'), findsOneWidget);
      expect(find.text('Week Warrior'), findsNothing);
      expect(find.text('Synced Up'), findsNothing);
    });

    testWidgets('filtering to Consistency reaches the cross-module set', (
      tester,
    ) async {
      await pumpScreen(tester, const Locale('en'));
      await tapChip(tester, 'Consistency');

      expect(find.text('Synced Up'), findsOneWidget);
      expect(find.text('Week Warrior'), findsNothing);
      expect(find.text('Health Hero'), findsNothing);
    });

    testWidgets('the new chips are localized too', (tester) async {
      await pumpScreen(tester, const Locale('tr'));

      expect(find.widgetWithText(ChoiceChip, 'İlaç'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Tutarlılık'), findsOneWidget);
    });
  });
}
