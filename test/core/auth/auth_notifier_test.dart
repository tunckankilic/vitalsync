import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vitalsync/core/auth/auth_provider.dart';
import 'package:vitalsync/core/errors/auth_exceptions.dart';
import 'package:vitalsync/domain/models/app_auth_result.dart';
import 'package:vitalsync/domain/models/app_user.dart';
import 'package:vitalsync/domain/repositories/shared/auth_repository.dart';

// ── Mocks ────────────────────────────────────────────────────────────────────

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuth;
  late ProviderContainer container;

  const email = 'jane@example.com';
  const password = 'S3cret!!';
  const name = 'Jane';

  const appUser = AppUser(
    id: 'cognito-sub-123',
    email: email,
    displayName: name,
  );
  const successResult = AppAuthResult(user: appUser);
  const newUserResult = AppAuthResult(user: appUser, isNewUser: true);

  setUp(() {
    mockAuth = MockAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(mockAuth)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  AuthNotifier notifier() => container.read(authProvider.notifier);

  // ── Sign in (login) ────────────────────────────────────────────────────────

  group('AuthNotifier.signIn', () {
    test('returns the auth result and ends in data state on success', () async {
      when(
        () => mockAuth.signIn(email, password),
      ).thenAnswer((_) async => successResult);

      final result = await notifier().signIn(email, password);

      expect(result.user.id, appUser.id);
      expect(result.isNewUser, isFalse);
      expect(container.read(authProvider).hasError, isFalse);
      verify(() => mockAuth.signIn(email, password)).called(1);
    });

    test('rethrows and ends in error state on wrong credentials', () async {
      when(
        () => mockAuth.signIn(email, password),
      ).thenThrow(const SignInFailedException('Incorrect email or password'));

      await expectLater(
        notifier().signIn(email, password),
        throwsA(isA<SignInFailedException>()),
      );

      expect(container.read(authProvider).hasError, isTrue);
    });

    test('propagates a network failure', () async {
      when(
        () => mockAuth.signIn(email, password),
      ).thenThrow(Exception('Network unreachable'));

      await expectLater(
        notifier().signIn(email, password),
        throwsA(isA<Exception>()),
      );
      expect(container.read(authProvider).hasError, isTrue);
    });
  });

  // ── Sign up (register) ───────────────────────────────────────────────────

  group('AuthNotifier.signUp', () {
    test('returns a new-user result on success', () async {
      when(
        () => mockAuth.signUp(email, password, name),
      ).thenAnswer((_) async => newUserResult);

      final result = await notifier().signUp(email, password, name);

      expect(result.isNewUser, isTrue);
      expect(container.read(authProvider).hasError, isFalse);
      verify(() => mockAuth.signUp(email, password, name)).called(1);
    });

    test('rethrows and ends in error state on failure', () async {
      when(
        () => mockAuth.signUp(email, password, name),
      ).thenThrow(const SignUpFailedException('Email already registered'));

      await expectLater(
        notifier().signUp(email, password, name),
        throwsA(isA<SignUpFailedException>()),
      );
      expect(container.read(authProvider).hasError, isTrue);
    });
  });

  // ── Apple Sign-In ──────────────────────────────────────────────────────────

  group('AuthNotifier.signInWithApple', () {
    test('returns the auth result on success', () async {
      when(
        () => mockAuth.signInWithApple(),
      ).thenAnswer((_) async => successResult);

      final result = await notifier().signInWithApple();

      expect(result.user.id, appUser.id);
      expect(container.read(authProvider).hasError, isFalse);
      verify(() => mockAuth.signInWithApple()).called(1);
    });

    test('rethrows and ends in error state when cancelled/failed', () async {
      when(
        () => mockAuth.signInWithApple(),
      ).thenThrow(const SignInFailedException('Apple sign-in was cancelled'));

      await expectLater(
        notifier().signInWithApple(),
        throwsA(isA<SignInFailedException>()),
      );
      expect(container.read(authProvider).hasError, isTrue);
    });
  });

  // ── Sign out ────────────────────────────────────────────────────────────────

  group('AuthNotifier.signOut', () {
    test('completes and ends in data state on success', () async {
      when(() => mockAuth.signOut()).thenAnswer((_) async {});

      await notifier().signOut();

      expect(container.read(authProvider).hasError, isFalse);
      verify(() => mockAuth.signOut()).called(1);
    });

    test('rethrows and ends in error state on failure', () async {
      when(() => mockAuth.signOut()).thenThrow(Exception('Sign-out failed'));

      await expectLater(notifier().signOut(), throwsA(isA<Exception>()));
      expect(container.read(authProvider).hasError, isTrue);
    });
  });

  // ── Reset password ──────────────────────────────────────────────────────────

  group('AuthNotifier.resetPassword', () {
    test('completes on success', () async {
      when(() => mockAuth.resetPassword(email)).thenAnswer((_) async {});

      await notifier().resetPassword(email);

      expect(container.read(authProvider).hasError, isFalse);
      verify(() => mockAuth.resetPassword(email)).called(1);
    });

    test('rethrows and ends in error state on network failure', () async {
      when(
        () => mockAuth.resetPassword(email),
      ).thenThrow(Exception('Network unreachable'));

      await expectLater(
        notifier().resetPassword(email),
        throwsA(isA<Exception>()),
      );
      expect(container.read(authProvider).hasError, isTrue);
    });
  });
}
