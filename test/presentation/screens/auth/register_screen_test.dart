// Widget tests for the Register screen — the account-creation entry point.
//
// Exercises rendering, form validation and the failure path (SnackBar, no
// navigation), so no GoRouter is required.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalsync/core/auth/auth_provider.dart';
import 'package:vitalsync/core/errors/auth_exceptions.dart';
import 'package:vitalsync/domain/repositories/shared/auth_repository.dart';
import 'package:vitalsync/presentation/screens/auth/register_screen.dart';

import '../../../support/pump_app.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuth;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockAuth = MockAuthRepository();
  });

  Future<void> pumpRegister(WidgetTester tester) {
    return pumpScreen(
      tester,
      const RegisterScreen(),
      overrides: [authRepositoryProvider.overrideWithValue(mockAuth)],
    );
  }

  /// Fills the form with input that passes every validator.
  Future<void> fillValidForm(WidgetTester tester) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Jane Doe'); // name
    await tester.enterText(fields.at(1), 'jane@example.com'); // email
    await tester.enterText(fields.at(2), 'secret1'); // password (>= 6)
    await tester.enterText(fields.at(3), 'secret1'); // confirm (matches)
  }

  testWidgets('renders the four form fields and a register button',
      (tester) async {
    await pumpRegister(tester);
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsNWidgets(4));
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('does not call signUp when the form is empty (validation)',
      (tester) async {
    await pumpRegister(tester);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byType(ElevatedButton));
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    verifyNever(() => mockAuth.signUp(any(), any(), any()));
  });

  testWidgets('calls signUp and surfaces a SnackBar when registration fails',
      (tester) async {
    when(() => mockAuth.signUp(any(), any(), any()))
        .thenThrow(const SignUpFailedException('Email already registered'));

    await pumpRegister(tester);
    await tester.pumpAndSettle();

    await fillValidForm(tester);
    await tester.ensureVisible(find.byType(ElevatedButton));
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump(); // validation + start async signUp
    await tester.pump(); // failed future settles + SnackBar shows

    verify(
      () => mockAuth.signUp('jane@example.com', 'secret1', 'Jane Doe'),
    ).called(1);
    expect(find.byType(SnackBar), findsOneWidget);

    await tester.pump(const Duration(seconds: 5)); // drain SnackBar timer
  });
}
