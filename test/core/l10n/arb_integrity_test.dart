import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The .arb files are JSON, and JSON lets the last definition of a repeated key
/// win. Nothing complains: not the parser, not gen-l10n, not `flutter analyze`.
/// A duplicate therefore looks exactly like a working key until someone edits
/// the wrong copy, and their change simply has no effect.
///
/// app_en.arb had fourteen of them. Three had already drifted — themeSystem,
/// themeLight and themeDark each held two different English strings, and the
/// app shipped whichever came last. These tests are the alarm for that.
void main() {
  final locales = ['en', 'tr', 'de'];

  File arb(String locale) => File('lib/core/l10n/app_$locale.arb');

  /// Keys in file order, including repeats. Reading the raw lines is the point:
  /// `json.decode` collapses duplicates and would hide what is being checked.
  List<String> declaredKeys(String locale) {
    final pattern = RegExp(r'^  "(\w+)"\s*:');
    return arb(locale)
        .readAsLinesSync()
        .map((line) => pattern.firstMatch(line)?.group(1))
        .whereType<String>()
        .toList();
  }

  Set<String> translatableKeys(String locale) {
    final map = json.decode(arb(locale).readAsStringSync()) as Map<String, Object?>;
    return map.keys.where((k) => !k.startsWith('@')).toSet();
  }

  for (final locale in locales) {
    test('app_$locale.arb declares every key exactly once', () {
      final keys = declaredKeys(locale);
      final duplicates = <String>{};
      final seen = <String>{};
      for (final key in keys) {
        if (!seen.add(key)) duplicates.add(key);
      }

      expect(
        duplicates,
        isEmpty,
        reason:
            'app_$locale.arb defines these keys more than once: '
            '${duplicates.toList()..sort()}. The last definition silently '
            'wins, so editing any earlier one does nothing.',
      );
    });
  }

  test('all three locales carry the same key set', () {
    final en = translatableKeys('en');
    for (final locale in ['tr', 'de']) {
      final other = translatableKeys(locale);
      expect(
        other.difference(en),
        isEmpty,
        reason: 'app_$locale.arb has keys app_en.arb does not',
      );
      expect(
        en.difference(other),
        isEmpty,
        reason:
            'app_$locale.arb is missing keys from app_en.arb. gen-l10n will '
            'silently fall back to English for them rather than failing.',
      );
    }
  });
}
