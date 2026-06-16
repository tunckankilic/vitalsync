// Widget tests for the GDPR consent screen (Settings -> Manage Consents).
//
// The screen now reflects the persisted consent map (read via
// sharedPreferencesProvider) and writes through GDPRManager, so both are
// overridden here: seeded mock prefs drive what the toggles show, and a mock
// manager records the writes the toggles trigger.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalsync/core/constants/app_constants.dart';
import 'package:vitalsync/core/gdpr/gdpr_manager.dart';
import 'package:vitalsync/core/settings/settings_provider.dart';
import 'package:vitalsync/presentation/screens/gdpr/consent_screen.dart';

import '../../../support/pump_app.dart';

class _MockGdprManager extends Mock implements GDPRManager {}

void main() {
  // Switch order follows the source: health, fitness, analytics, cloud.
  const healthSwitch = 0;
  const analyticsSwitch = 2;

  late SharedPreferences prefs;
  late _MockGdprManager manager;

  int onSwitchCount(WidgetTester tester) => tester
      .widgetList<Switch>(find.byType(Switch))
      .where((s) => s.value)
      .length;

  // The four consent cards are taller than the default 800x600 test viewport,
  // so the last one is lazily kept out of the ListView. Use a tall surface so
  // all four toggles are laid out and findable.
  Future<void> pumpConsent(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpScreen(
      tester,
      const ConsentScreen(isOnboarding: true),
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        gdprManagerProvider.overrideWithValue(manager),
      ],
    );
    await tester.pumpAndSettle();
  }

  setUp(() async {
    // Health + fitness granted (the state after onboarding), analytics + cloud
    // still off — the realistic state when opening Settings -> Manage Consents.
    SharedPreferences.setMockInitialValues({
      AppConstants.prefKeyHealthDataConsent: true,
      AppConstants.prefKeyFitnessDataConsent: true,
      AppConstants.prefKeyAnalyticsConsent: false,
      AppConstants.prefKeyCloudBackupConsent: false,
    });
    prefs = await SharedPreferences.getInstance();
    manager = _MockGdprManager();
    when(() => manager.grantConsent(any())).thenAnswer((_) async {});
    when(() => manager.revokeConsent(any())).thenAnswer((_) async {});
  });

  testWidgets('renders four consent toggles reflecting persisted consent',
      (tester) async {
    await pumpConsent(tester);

    expect(find.byType(Switch), findsNWidgets(4));
    // Health + fitness are granted in prefs; analytics + cloud are not.
    expect(onSwitchCount(tester), 2);
    expect(find.byType(ElevatedButton), findsOneWidget); // continue gate
  });

  testWidgets('enabling an optional consent persists it via GDPRManager',
      (tester) async {
    await pumpConsent(tester);

    final analytics = find.byType(Switch).at(analyticsSwitch);
    await tester.ensureVisible(analytics);
    await tester.tap(analytics);
    await tester.pumpAndSettle();

    verify(
      () => manager.grantConsent(AppConstants.gdprConsentTypeAnalytics),
    ).called(1);
  });

  testWidgets('blocks turning off a required consent and warns the user',
      (tester) async {
    await pumpConsent(tester);

    final health = find.byType(Switch).at(healthSwitch);
    await tester.ensureVisible(health);
    await tester.tap(health); // attempt to disable a required consent
    await tester.pump();

    // Required consent stays on, the user is warned, and nothing is revoked.
    expect(onSwitchCount(tester), 2);
    expect(find.byType(SnackBar), findsOneWidget);
    verifyNever(() => manager.revokeConsent(any()));

    await tester.pump(const Duration(seconds: 5)); // drain SnackBar timer
  });
}
