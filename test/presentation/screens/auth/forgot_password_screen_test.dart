// Widget tests for the Forgot Password screen — the account-recovery entry
// point.
//
// Exercises rendering, form validation and the failure path (SnackBar, no
// navigation). The success path calls `context.go('/auth/login')`, which needs
// a router, so these tests deliberately avoid triggering it — the auth notifier
// rethrows on error, keeping a failed reset on the same screen.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalsync/core/auth/auth_provider.dart';
import 'package:vitalsync/core/errors/auth_exceptions.dart';
import 'package:vitalsync/domain/repositories/shared/auth_repository.dart';
import 'package:vitalsync/presentation/screens/auth/forgot_password_screen.dart';

import '../../../support/pump_app.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuth;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockAuth = MockAuthRepository();
  });

  Future<void> pumpForgotPassword(WidgetTester tester) {
    return pumpScreen(
      tester,
      const ForgotPasswordScreen(),
      overrides: [authRepositoryProvider.overrideWithValue(mockAuth)],
    );
  }

  testWidgets('renders the email field and a send-reset button',
      (tester) async {
    await pumpForgotPassword(tester);
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('does not call resetPassword when the email is empty (validation)',
      (tester) async {
    await pumpForgotPassword(tester);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byType(ElevatedButton));
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    verifyNever(() => mockAuth.resetPassword(any()));
  });

  testWidgets('calls resetPassword and surfaces a SnackBar when it fails',
      (tester) async {
    when(() => mockAuth.resetPassword(any()))
        .thenThrow(const SignInFailedException('User not found'));

    await pumpForgotPassword(tester);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'jane@example.com');
    await tester.ensureVisible(find.byType(ElevatedButton));
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump(); // validation + start async resetPassword
    await tester.pump(); // failed future settles + SnackBar shows

    verify(() => mockAuth.resetPassword('jane@example.com')).called(1);
    expect(find.byType(SnackBar), findsOneWidget);

    await tester.pump(const Duration(seconds: 5)); // drain SnackBar timer
  });
}
