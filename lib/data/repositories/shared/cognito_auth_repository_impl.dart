/// VitalSync — AWS Cognito AuthRepository Implementation.
///
/// Implements [AuthRepository] using Amplify Auth (Cognito).
/// Manages auth state via Amplify Hub events.
library;

import 'dart:async';
import 'dart:developer' show log;

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:vitalsync/core/errors/auth_exceptions.dart';
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
          // Guarded so a fetch failure right after sign-in can't throw out of
          // the Hub callback (which would leave _cachedUser stale and the
          // stream un-notified).
          try {
            _cachedUser = await _fetchCurrentUser();
          } catch (e) {
            log('Failed to load user after sign-in: $e');
            _cachedUser = null;
          }
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
    // Identity first. The userId from getCurrentUser() is what scopes cloud
    // sync, so it is fetched on its own and must survive independently of the
    // display attributes below.
    final String userId;
    try {
      final authUser = await Amplify.Auth.getCurrentUser();
      userId = authUser.userId;
    } on SignedOutException {
      return null;
    }

    // Attributes (name/email) are display-only. Fetch them in their own guard
    // so a failure here never nulls the whole identity. Previously a thrown
    // fetchUserAttributes() — e.g. a federated Apple user whose attribute
    // mapping isn't fully provisioned — left currentUser null, and sync was
    // then silently skipped ("User not authenticated"). Identity no longer
    // depends on attributes succeeding.
    String? email;
    String? name;
    String? givenName;
    String? familyName;
    var emailVerified = false;
    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();
      for (final attr in attributes) {
        switch (attr.userAttributeKey.key) {
          case 'email':
            email = attr.value;
          case 'email_verified':
            emailVerified = attr.value == 'true';
          case 'name':
            name = attr.value;
          case 'given_name':
            givenName = attr.value;
          case 'family_name':
            familyName = attr.value;
        }
      }
    } catch (e) {
      log('Failed to fetch user attributes (identity preserved): $e');
    }

    // Sign in with Apple (via Cognito) supplies the user's name as
    // firstName/lastName — which Cognito maps to `given_name`/`family_name`,
    // not the single `name` attribute — and only on the first authorization.
    // Prefer an explicit `name`, but fall back to composing one from
    // given/family so federated users aren't shown as a blank "User".
    final composedName = [givenName, familyName]
        .where((part) => part != null && part.trim().isNotEmpty)
        .join(' ')
        .trim();
    final displayName = (name != null && name.trim().isNotEmpty)
        ? name
        : (composedName.isNotEmpty ? composedName : null);

    return AppUser(
      id: userId,
      email: email,
      displayName: displayName,
      emailVerified: emailVerified,
    );
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
        throw const EmailNotVerifiedException(
          'Email doğrulaması gerekli. Lütfen e-postanıza gelen kodu girin.',
        );
      }
      throw SignInFailedException(
        'Giriş başarısız: ${result.nextStep.signInStep}',
      );
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

    throw SignUpFailedException(
      'Kayıt başarısız: ${result.nextStep.signUpStep}',
    );
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
      throw ConfirmationFailedException(
        'Doğrulama başarısız: ${result.nextStep.signUpStep}',
      );
    }
  }

  @override
  Future<AppAuthResult> signInWithGoogle() {
    throw UnimplementedError(
      'Google Sign-In is no longer supported. Use Apple Sign-In instead.',
    );
  }

  @override
  Future<AppAuthResult> signInWithApple() async {
    final result = await Amplify.Auth.signInWithWebUI(
      provider: AuthProvider.apple,
      options: const SignInWithWebUIOptions(
        pluginOptions: CognitoSignInWithWebUIPluginOptions(
          isPreferPrivateSession: false,
        ),
      ),
    );

    if (!result.isSignedIn) {
      throw const SignInFailedException(
        'Apple Sign-In tamamlanamadı.',
      );
    }

    _cachedUser = await _fetchCurrentUser();
    if (_cachedUser == null) {
      throw const SignInFailedException(
        'Apple Sign-In sonrası kullanıcı bilgileri alınamadı.',
      );
    }
    return AppAuthResult(user: _cachedUser!, isNewUser: false);
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
    // No additional profile creation needed.
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
