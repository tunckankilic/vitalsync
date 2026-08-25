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

  Future<void> pumpScreen(WidgetTester tester, Locale locale) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          achievementsProvider.overrideWith(
            (ref) => Stream.value([unlocked, locked]),
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
}
