import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalsync/core/enums/equipment.dart';
import 'package:vitalsync/core/enums/exercise_category.dart';
import 'package:vitalsync/core/enums/medication_frequency.dart';
import 'package:vitalsync/core/l10n/app_localizations.dart';
import 'package:vitalsync/features/fitness/presentation/fitness_labels.dart';
import 'package:vitalsync/features/health/presentation/health_labels.dart';

/// The switches themselves are exhaustive by the compiler, so a *missing* case
/// cannot ship. What can ship is a wrong case: twenty near-identical lines
/// invite a copy-paste that points two enum values at the same key, and that
/// is invisible — the screen just shows the same word twice.
///
/// A key missing from a translation is equally silent: gen-l10n falls back to
/// the English template rather than failing, so "the German build renders
/// English here" is a runtime-only symptom. Both are checked below.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final locales = {
    'en': lookupAppLocalizations(const Locale('en')),
    'tr': lookupAppLocalizations(const Locale('tr')),
    'de': lookupAppLocalizations(const Locale('de')),
  };

  void expectDistinctAndPresent(
    String enumName,
    Map<String, List<String>> labelsByLocale,
  ) {
    labelsByLocale.forEach((locale, labels) {
      for (final label in labels) {
        expect(
          label.trim(),
          isNotEmpty,
          reason: '$enumName has an empty label in $locale',
        );
      }
      expect(
        labels.toSet().length,
        labels.length,
        reason:
            '$enumName maps two values to the same string in $locale: $labels. '
            'Most likely two switch arms point at the same l10n key.',
      );
    });
  }

  group('ExerciseCategory.label', () {
    test('every value has a distinct, non-empty label in each locale', () {
      expectDistinctAndPresent('ExerciseCategory', {
        for (final entry in locales.entries)
          entry.key: ExerciseCategory.values
              .map((v) => v.label(entry.value))
              .toList(),
      });
    });

    test('is translated away from English in tr and de', () {
      for (final value in ExerciseCategory.values) {
        final english = value.label(locales['en']!);
        for (final locale in ['tr', 'de']) {
          // Kettlebell-style loanwords are equal across languages on purpose;
          // none of the categories are, so any match here means the key is
          // missing from that .arb and gen-l10n fell back to English.
          expect(
            value.label(locales[locale]!),
            isNot(english),
            reason:
                'ExerciseCategory.${value.name} renders the English '
                '"$english" in $locale',
          );
        }
      }
    });

    test('back is the muscle group, not the navigation button', () {
      // The generic `back` key means "Geri" / "Zurück". Pointing the category
      // at it would have labelled the back muscles "Back button" in every
      // non-English build, which is why the keys are namespaced.
      expect(ExerciseCategory.back.label(locales['tr']!), 'Sırt');
      expect(ExerciseCategory.back.label(locales['de']!), 'Rücken');
    });
  });

  group('Equipment.label', () {
    test('every value has a distinct, non-empty label in each locale', () {
      expectDistinctAndPresent('Equipment', {
        for (final entry in locales.entries)
          entry.key: Equipment.values.map((v) => v.label(entry.value)).toList(),
      });
    });
  });

  group('MedicationFrequency.label', () {
    test('every value has a distinct, non-empty label in each locale', () {
      expectDistinctAndPresent('MedicationFrequency', {
        for (final entry in locales.entries)
          entry.key: MedicationFrequency.values
              .map((v) => v.label(entry.value))
              .toList(),
      });
    });

    test('is translated away from English in tr and de', () {
      for (final value in MedicationFrequency.values) {
        final english = value.label(locales['en']!);
        for (final locale in ['tr', 'de']) {
          expect(
            value.label(locales[locale]!),
            isNot(english),
            reason:
                'MedicationFrequency.${value.name} renders the English '
                '"$english" in $locale',
          );
        }
      }
    });
  });

  group('displayName stays English', () {
    test('InsightEngine and the seed keep a language-independent name', () {
      // InsightEngine keys symptom/exercise correlations on this string and
      // persists it into the insight payload. It must not move with the UI
      // language, so the getter is kept and documented rather than replaced.
      expect(ExerciseCategory.back.displayName, 'Back');
      expect(Equipment.bodyweight.displayName, 'Bodyweight');
      expect(MedicationFrequency.asNeeded.displayName, 'As Needed');
    });
  });
}
