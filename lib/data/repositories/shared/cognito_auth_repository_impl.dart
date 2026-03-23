/// VitalSync — AWS Cognito AuthRepository Implementation.
///
/// Implements [AuthRepository] using Amplify Auth (Cognito).
/// Manages auth state via Amplify Hub events.
library;

import 'dart:async';
import 'dart:developer' show log;

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:vitalsync/domain/models/app_auth_result.dart';
import 'package:vitalsync/domain/models/app_user.dart';
import 'package:vitalsync/domain/repositories/shared/auth_repository.dart';

class CognitoAuthRepositoryImpl implements AuthRepository {
  CognitoAuthRepositoryImpl() {
    _initAuthStream();
  }

  AppUser? _cachedUser;
  final _authStateController = StreamController<AppUser?>.broadcast();
  StreamSubscription<AuthHubEvent>? _hubSubscription;

  void _initAuthStream() {
    // Listen to Amplify Hub auth events
    _hubSubscription = Amplify.Hub.listen(HubChannel.Auth, (event) async {
      switch (event.type) {
        case AuthHubEventType.signedIn:
          _cachedUser = await _fetchCurrentUser();
          _authStateController.add(_cachedUser);
        case AuthHubEventType.signedOut:
        case AuthHubEventType.sessionExpired:
        case AuthHubEventType.userDeleted:
          _cachedUser = null;
          _authStateController.add(null);
      }
    });

    // Check initial auth state
    _checkInitialAuthState();
  }

  Future<void> _checkInitialAuthState() async {
    try {
      _cachedUser = await _fetchCurrentUser();
      _authStateController.add(_cachedUser);
    } on SignedOutException {
      _cachedUser = null;
      _authStateController.add(null);
    } catch (e) {
      log('Initial auth state check failed: $e');
      _cachedUser = null;
      _authStateController.add(null);
    }
  }

  /// Fetches the current authenticated user from Cognito.
  Future<AppUser?> _fetchCurrentUser() async {
    try {
      final authUser = await Amplify.Auth.getCurrentUser();
      final attributes = await Amplify.Auth.fetchUserAttributes();

      String? email;
      String? displayName;
      var emailVerified = false;

      for (final attr in attributes) {
        switch (attr.userAttributeKey.key) {
          case 'email':
            email = attr.value;
          case 'email_verified':
            emailVerified = attr.value == 'true';
          case 'name':
            displayName = attr.value;
        }
      }

      return AppUser(
        id: authUser.userId,
        email: email,
        displayName: displayName,
        emailVerified: emailVerified,
      );
    } on SignedOutException {
      return null;
    }
  }

  @override
  Stream<AppUser?> get authStateChanges => _authStateController.stream;

  @override
  AppUser? get currentUser => _cachedUser;

  @override
  Future<AppAuthResult> signIn(String email, String password) async {
    final result = await Amplify.Auth.signIn(
      username: email,
      password: password,
    );

    if (!result.isSignedIn) {
      if (result.nextStep.signInStep == AuthSignInStep.confirmSignUp) {
        throw Exception(
          'Email doğrulaması gerekli. Lütfen e-postanıza gelen kodu girin.',
        );
      }
      throw Exception('Giriş başarısız: ${result.nextStep.signInStep}');
    }

    _cachedUser = await _fetchCurrentUser();
    return AppAuthResult(user: _cachedUser!, isNewUser: false);
  }

  @override
  Future<AppAuthResult> signUp(
    String email,
    String password,
    String name,
  ) async {
    final result = await Amplify.Auth.signUp(
      username: email,
      password: password,
      options: SignUpOptions(
        userAttributes: {
          AuthUserAttributeKey.email: email,
          AuthUserAttributeKey.name: name,
        },
      ),
    );

    if (result.nextStep.signUpStep == AuthSignUpStep.confirmSignUp) {
      // Return a partial user — UI should show confirmation code screen
      return AppAuthResult(
        user: AppUser(id: '', email: email, displayName: name),
        isNewUser: true,
      );
    }

    // Auto-confirmed (e.g., via Lambda trigger)
    if (result.isSignUpComplete) {
      final signInResult = await signIn(email, password);
      return AppAuthResult(user: signInResult.user, isNewUser: true);
    }

    throw Exception('Kayıt başarısız: ${result.nextStep.signUpStep}');
  }

  @override
  Future<void> confirmSignUp(
    String email,
    String confirmationCode,
  ) async {
    final result = await Amplify.Auth.confirmSignUp(
      username: email,
      confirmationCode: confirmationCode,
    );

    if (!result.isSignUpComplete) {
      throw Exception('Doğrulama başarısız: ${result.nextStep.signUpStep}');
    }
  }

  @override
  Future<AppAuthResult> signInWithGoogle() {
    throw UnimplementedError(
      'Google Sign-In is no longer supported. Use Apple Sign-In instead.',
    );
  }

  @override
  Future<AppAuthResult> signInWithApple() {
    // Apple Sign-In requires OIDC federation setup in Cognito User Pool.
    // This will be configured separately via AWS Console.
    throw UnimplementedError(
      'Apple Sign-In OIDC is not configured yet. '
      'Configure Apple as a social identity provider in Cognito first.',
    );
  }

  @override
  Future<void> signOut() async {
    await Amplify.Auth.signOut();
    _cachedUser = null;
  }

  @override
  Future<void> resetPassword(String email) async {
    await Amplify.Auth.resetPassword(username: email);
    // Cognito sends a verification code to the email.
    // UI should show confirmResetPassword screen next.
  }

  @override
  Future<void> confirmResetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    await Amplify.Auth.confirmResetPassword(
      username: email,
      newPassword: newPassword,
      confirmationCode: code,
    );
  }

  @override
  Future<void> createInitialProfile(AppUser user, String name) async {
    // Cognito stores name as a user attribute — already set during signUp.
    // No additional profile creation needed (unlike Firestore).
    // If needed later, push a profile record via RestSyncClient.
  }

  @override
  Future<void> deleteAccount() async {
    await Amplify.Auth.deleteUser();
    _cachedUser = null;
  }

  /// Dispose resources.
  void dispose() {
    _hubSubscription?.cancel();
    _authStateController.close();
  }
}
