// Widget tests for the Login screen — the app's primary auth entry point.
//
// These exercise rendering, form validation and the failure path (which shows
// a SnackBar rather than navigating), so no GoRouter is needed.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalsync/core/auth/auth_provider.dart';
import 'package:vitalsync/core/errors/auth_exceptions.dart';
import 'package:vitalsync/domain/repositories/shared/auth_repository.dart';
import 'package:vitalsync/presentation/screens/auth/login_screen.dart';

import 'support/pump_app.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuth;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockAuth = MockAuthRepository();
  });

  Future<void> pumpLogin(WidgetTester tester) {
    return pumpScreen(
      tester,
      const LoginScreen(),
      overrides: [authRepositoryProvider.overrideWithValue(mockAuth)],
    );
  }

  testWidgets('renders the email/password form and a login button',
      (tester) async {
    await pumpLogin(tester);
    await tester.pumpAndSettle(); // drain entry animations

    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('does not call signIn when the form is empty (validation)',
      (tester) async {
    await pumpLogin(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    verifyNever(() => mockAuth.signIn(any(), any()));
  });

  testWidgets('calls signIn and surfaces a SnackBar on failed credentials',
      (tester) async {
    when(() => mockAuth.signIn(any(), any()))
        .thenThrow(const SignInFailedException('Incorrect email or password'));

    await pumpLogin(tester);
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'jane@example.com');
    await tester.enterText(fields.at(1), 'wrong-password');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump(); // run validation + start async signIn
    await tester.pump(); // let the failed future settle + show SnackBar

    verify(() => mockAuth.signIn('jane@example.com', 'wrong-password'))
        .called(1);
    expect(find.byType(SnackBar), findsOneWidget);

    // Drain the SnackBar auto-dismiss timer so no timer outlives the test.
    await tester.pump(const Duration(seconds: 5));
  });
}
