import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalsync/core/enums/achievement_type.dart';
import 'package:vitalsync/core/l10n/achievement_labels.dart';
import 'package:vitalsync/core/l10n/app_localizations.dart';
import 'package:vitalsync/data/local/database.dart';
import 'package:vitalsync/data/local/seed_data.dart';
import 'package:vitalsync/domain/entities/fitness/achievement.dart';

/// Achievements are stored as English rows and translated at display time by
/// their `iconName`. That only holds while the seed and the translation
/// switches agree, and a disagreement is silent — the switch falls through to
/// the stored English. These tests are the alarm for that.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late List<String> seededIconNames;

  setUpAll(() async {
    db = AppDatabase(NativeDatabase.memory());
    await seedDatabase(db);
    final rows = await db.select(db.achievements).get();
    seededIconNames = rows.map((r) => r.iconName).toList();
  });

  tearDownAll(() => db.close());

  final locales = {
    'en': lookupAppLocalizations(const Locale('en')),
    'tr': lookupAppLocalizations(const Locale('tr')),
    'de': lookupAppLocalizations(const Locale('de')),
  };

  Achievement achievementWith(String iconName) => Achievement(
    id: 1,
    type: AchievementType.streak,
    title: 'STORED TITLE',
    description: 'STORED DESCRIPTION',
    requirement: 7,
    iconName: iconName,
  );

  group('seed and translations stay in step', () {
    test('every seeded achievement is translated', () {
      expect(seededIconNames, isNotEmpty);
      expect(
        seededIconNames.toSet().difference(kLocalizedAchievementIconNames),
        isEmpty,
        reason:
            'a seeded achievement has no translation and would silently '
            'render in English',
      );
    });

    test('no translation is left over for an achievement that was removed', () {
      expect(
        kLocalizedAchievementIconNames.difference(seededIconNames.toSet()),
        isEmpty,
      );
    });

    test('icon names are unique, so one row means one translation', () {
      expect(seededIconNames.toSet(), hasLength(seededIconNames.length));
    });
  });

  group('every achievement resolves in every language', () {
    for (final entry in locales.entries) {
      test('${entry.key} has a title and a description for each', () {
        for (final iconName in kLocalizedAchievementIconNames) {
          final achievement = achievementWith(iconName);
          final title = achievement.localizedTitle(entry.value);
          final description = achievement.localizedDescription(entry.value);

          // The stored strings are the fallback, so seeing them here means
          // the switch did not match.
          expect(title, isNotEmpty, reason: iconName);
          expect(title, isNot('STORED TITLE'), reason: iconName);
          expect(description, isNotEmpty, reason: iconName);
          expect(description, isNot('STORED DESCRIPTION'), reason: iconName);
        }
      });
    }

    test('Turkish and German descriptions are actually translated', () {
      for (final iconName in kLocalizedAchievementIconNames) {
        final achievement = achievementWith(iconName);
        final english = achievement.localizedDescription(locales['en']!);

        // Titles are exempt: a few are proper nouns that stay put ("Elite").
        // A description repeating the English one is an untranslated string.
        expect(
          achievement.localizedDescription(locales['tr']!),
          isNot(english),
          reason: iconName,
        );
        expect(
          achievement.localizedDescription(locales['de']!),
          isNot(english),
          reason: iconName,
        );
      }
    });
  });

  group('an unknown achievement degrades instead of breaking', () {
    test('falls back to the stored text', () {
      final unknown = achievementWith('some_achievement_added_later');

      for (final l10n in locales.values) {
        expect(unknown.localizedTitle(l10n), 'STORED TITLE');
        expect(unknown.localizedDescription(l10n), 'STORED DESCRIPTION');
      }
    });
  });
}
