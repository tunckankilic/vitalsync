import 'dart:async';

import 'package:vitalsync/domain/models/app_auth_result.dart';
import 'package:vitalsync/domain/models/app_user.dart';
import 'package:vitalsync/domain/repositories/shared/auth_repository.dart';

/// Minimal in-memory [AuthRepository] for provider/widget tests.
///
/// Records the calls the auth flows make and lets individual tests seed the
/// signed-in user or force failures — no Amplify or GetIt wiring required.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.user});

  /// The signed-in user reported by [currentUser].
  AppUser? user;

  final _controller = StreamController<AppUser?>.broadcast();

  /// `(email, code)` arguments captured from [confirmSignUp] calls.
  final confirmSignUpCalls = <(String, String)>[];

  /// When set, the matching method throws after recording its arguments.
  Exception? confirmSignUpError;

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  @override
  AppUser? get currentUser => user;

  /// Pushes an auth event, as the real repository does on Amplify Hub events.
  void emit(AppUser? nextUser) {
    user = nextUser;
    _controller.add(nextUser);
  }

  void dispose() {
    _controller.close();
  }

  @override
  Future<void> confirmSignUp(String email, String confirmationCode) async {
    confirmSignUpCalls.add((email, confirmationCode));
    final error = confirmSignUpError;
    if (error != null) throw error;
  }

  @override
  Future<AppUser?> refreshCurrentUser() async => user;

  // The flows under test never reach the members below.
  @override
  Future<AppAuthResult> signIn(String email, String password) =>
      throw UnimplementedError();

  @override
  Future<AppAuthResult> signUp(String email, String password, String name) =>
      throw UnimplementedError();

  @override
  Future<AppAuthResult> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<AppAuthResult> signInWithApple() => throw UnimplementedError();

  @override
  Future<void> signOut() => throw UnimplementedError();

  @override
  Future<void> resetPassword(String email) => throw UnimplementedError();

  @override
  Future<void> confirmResetPassword(
    String email,
    String code,
    String newPassword,
  ) => throw UnimplementedError();

  @override
  Future<void> createInitialProfile(AppUser user, String name) =>
      throw UnimplementedError();

  @override
  Future<void> updateDisplayName(String name) => throw UnimplementedError();

  @override
  Future<void> deleteAccount() => throw UnimplementedError();
}
