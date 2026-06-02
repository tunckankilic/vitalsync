// Widget tests for the GDPR consent screen — the compliance gate every new
// user passes through during onboarding.
//
// The consent providers are plain in-memory Notifiers, so no backend or
// SharedPreferences setup is needed; each pump gets a fresh ProviderScope.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalsync/presentation/screens/gdpr/consent_screen.dart';

import '../../../support/pump_app.dart';

void main() {
  // Switch order follows the source: health, fitness, analytics, cloud.
  const healthSwitch = 0;
  const analyticsSwitch = 2;

  int onSwitchCount(WidgetTester tester) => tester
      .widgetList<Switch>(find.byType(Switch))
      .where((s) => s.value)
      .length;

  // The four consent cards are taller than the default 800x600 test viewport,
  // so the last one is lazily kept out of the ListView. Use a tall surface so
  // all four toggles are laid out and findable.
  Future<void> useTallSurface(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('renders four consent toggles with the required ones pre-enabled',
      (tester) async {
    await useTallSurface(tester);
    await pumpScreen(tester, const ConsentScreen(isOnboarding: true));
    await tester.pumpAndSettle();

    expect(find.byType(Switch), findsNWidgets(4));
    // Health + fitness are required and default ON; analytics + cloud default OFF.
    expect(onSwitchCount(tester), 2);
    expect(find.byType(ElevatedButton), findsOneWidget); // continue gate
  });

  testWidgets('enabling an optional consent (analytics) toggles it on',
      (tester) async {
    await useTallSurface(tester);
    await pumpScreen(tester, const ConsentScreen(isOnboarding: true));
    await tester.pumpAndSettle();

    final analytics = find.byType(Switch).at(analyticsSwitch);
    await tester.ensureVisible(analytics);
    await tester.tap(analytics);
    await tester.pumpAndSettle();

    expect(onSwitchCount(tester), 3); // analytics now on
  });

  testWidgets('blocks turning off a required consent and warns the user',
      (tester) async {
    await useTallSurface(tester);
    await pumpScreen(tester, const ConsentScreen(isOnboarding: true));
    await tester.pumpAndSettle();

    final health = find.byType(Switch).at(healthSwitch);
    await tester.ensureVisible(health);
    await tester.tap(health); // attempt to disable a required consent
    await tester.pump();

    // Required consent stays on, and the user is warned via a SnackBar.
    expect(onSwitchCount(tester), 2);
    expect(find.byType(SnackBar), findsOneWidget);

    await tester.pump(const Duration(seconds: 5)); // drain SnackBar timer
  });
}
