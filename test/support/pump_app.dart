import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalsync/core/l10n/app_localizations.dart';

/// Pumps [screen] inside the minimal app scaffolding the presentation screens
/// expect: a [ProviderScope] (with optional [overrides]) and a [MaterialApp]
/// wired with the app's localization delegates.
///
/// No router is installed — widget tests here exercise rendering, form
/// validation and failure paths, none of which navigate. (Success paths call
/// `context.go`, which these tests deliberately avoid triggering.)
/// Pass [locale] to render the screen in a specific language; omit it to take
/// the test environment's default (English).
Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  List<Override> overrides = const [],
  Locale? locale,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: screen,
      ),
    ),
  );
}
