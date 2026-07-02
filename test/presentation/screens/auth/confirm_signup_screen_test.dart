// Widget tests for the sign-up email confirmation screen.
//
// Follows the pump_app convention: rendering, validation and failure paths
// only — success paths call `context.go`, which these tests avoid triggering
// (except resend, which never navigates).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalsync/core/auth/auth_provider.dart';
import 'package:vitalsync/core/errors/auth_exceptions.dart';
import 'package:vitalsync/presentation/screens/auth/confirm_signup_screen.dart';

import '../../../support/fake_auth_repository.dart';
import '../../../support/pump_app.dart';

void main() {
  group('ConfirmSignUpScreen', () {
    const email = 'new.user@example.com';

    Future<FakeAuthRepository> pump(WidgetTester tester) async {
      final fake = FakeAuthRepository();
      addTearDown(fake.dispose);
      await pumpScreen(
        tester,
        const ConfirmSignUpScreen(email: email),
        overrides: [authRepositoryProvider.overrideWith((ref) => fake)],
      );
      return fake;
    }

    testWidgets('shows the email the code was sent to', (tester) async {
      await pump(tester);
      // Let the entrance animations (flutter_animate) run to completion so
      // no timers are left pending at the end of the test.
      await tester.pumpAndSettle();

      expect(find.text('Verify Your Email'), findsOneWidget);
      expect(find.textContaining(email), findsOneWidget);
    });

    testWidgets('rejects an empty code without calling the repository', (
      tester,
    ) async {
      final fake = await pump(tester);

      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter the verification code'), findsOneWidget);
      expect(fake.confirmSignUpCalls, isEmpty);
    });

    testWidgets('rejects a short code without calling the repository', (
      tester,
    ) async {
      final fake = await pump(tester);

      await tester.enterText(find.byType(TextFormField), '123');
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();

      expect(find.text('The code must be 6 digits'), findsOneWidget);
      expect(fake.confirmSignUpCalls, isEmpty);
    });

    testWidgets('submits the code and surfaces a confirmation failure', (
      tester,
    ) async {
      final fake = await pump(tester);
      fake.confirmSignUpError = const ConfirmationFailedException('bad code');

      await tester.enterText(find.byType(TextFormField), '123456');
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();

      expect(fake.confirmSignUpCalls, [(email, '123456')]);
      expect(find.textContaining('Verification failed'), findsOneWidget);
    });

    testWidgets('resend requests a fresh code and confirms via snackbar', (
      tester,
    ) async {
      final fake = await pump(tester);

      await tester.tap(find.text('Resend Code'));
      await tester.pumpAndSettle();

      expect(fake.resendSignUpCodeCalls, [email]);
      expect(
        find.text('A new verification code was sent to your email.'),
        findsOneWidget,
      );
    });

    testWidgets('surfaces a resend failure', (tester) async {
      final fake = await pump(tester);
      fake.resendSignUpCodeError = Exception('limit exceeded');

      await tester.tap(find.text('Resend Code'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Could not resend the code'), findsOneWidget);
    });
  });
}
