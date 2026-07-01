/// VitalSync — AWS Cognito AuthRepository Implementation.
///
/// Implements [AuthRepository] using Amplify Auth (Cognito).
/// Manages auth state via Amplify Hub events.
library;

import 'dart:async';
import 'dart:developer' show log;

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:vitalsync/core/auth/apple_token_revocation_service.dart';
import 'package:vitalsync/core/errors/auth_exceptions.dart';
import 'package:vitalsync/core/errors/exceptions.dart'
    show AccountDeletionException;
import 'package:vitalsync/domain/models/app_auth_result.dart';
import 'package:vitalsync/domain/models/app_user.dart';
import 'package:vitalsync/domain/repositories/shared/auth_repository.dart';

class CognitoAuthRepositoryImpl implements AuthRepository {
  CognitoAuthRepositoryImpl({AppleTokenRevocationService? revocationService})
    : _revocationService = revocationService {
    _initAuthStream();
  }

  /// Revokes the Sign in with Apple grant on account deletion. Optional: when
  /// null (or unconfigured) the revoke step is skipped entirely.
  final AppleTokenRevocationService? _revocationService;

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

    // Build the display name from first + last parts. `name` carries the full
    // name for email/password sign-up, but only the FIRST name for Sign in with
    // Apple — this pool maps Apple firstName -> name and lastName ->
    // family_name (given_name is left unmapped, kept here as an extra fallback).
    // Combining them yields a complete name for both, instead of showing only
    // the first name or a blank "User". Apple only sends the name on the first
    // authorization, so it may legitimately be absent for returning users.
    final firstPart = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : givenName?.trim();
    final lastPart = familyName?.trim();
    final composedName = [
      firstPart,
      lastPart,
    ].where((part) => part != null && part.isNotEmpty).join(' ').trim();
    final displayName = composedName.isNotEmpty ? composedName : null;

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
  Future<AppUser?> refreshCurrentUser() async {
    // Consult Amplify's persisted session rather than the in-memory cache, so a
    // valid session that hasn't been cached yet (cold-start race) is detected,
    // and a genuinely expired one is reported as such. Used by biometric unlock.
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (!session.isSignedIn) {
        _cachedUser = null;
        _authStateController.add(null);
        return null;
      }
      _cachedUser = await _fetchCurrentUser();
    } on SignedOutException {
      _cachedUser = null;
    } catch (e) {
      // Transient failure (e.g. no connectivity): keep whatever identity is
      // already cached instead of falsely reporting an expired session.
      log('refreshCurrentUser failed: $e');
    }
    _authStateController.add(_cachedUser);
    return _cachedUser;
  }

  @override
  Future<void> updateDisplayName(String name) async {
    // Persist the name on the Cognito `name` attribute so it survives a
    // reinstall and reaches other devices — important for Apple users, whose
    // name Apple only ever sends on the first authorization. Refresh the cache
    // afterwards so listeners (profile screen) update immediately.
    await Amplify.Auth.updateUserAttribute(
      userAttributeKey: AuthUserAttributeKey.name,
      value: name,
    );
    _cachedUser = await _fetchCurrentUser();
    _authStateController.add(_cachedUser);
  }

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
  Future<void> confirmSignUp(String email, String confirmationCode) async {
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
      throw const SignInFailedException('Apple Sign-In tamamlanamadı.');
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
    // Revoke the Sign in with Apple grant *before* deleting the Cognito user,
    // while the session (and thus the API authorizer token) is still valid.
    // Best-effort: a failure here must never block the deletion itself — it is
    // reported to crash reporting and swallowed (App Store Guideline 5.1.1(v)).
    await _revokeAppleGrantBestEffort();

    try {
      await Amplify.Auth.deleteUser();
    } catch (e) {
      // Surface a typed, cause-carrying failure so the GDPR erasure flow and
      // crash reporting get a consistent signal instead of a raw AuthException.
      // The cache is left untouched — on failure the account still exists.
      log('Account deletion failed: $e');
      throw AccountDeletionException('Account deletion failed.', cause: e);
    }
    _cachedUser = null;
  }

  /// Best-effort revocation of the Sign in with Apple grant for Apple-linked
  /// users. Never throws — a failure is reported and swallowed so the account
  /// deletion always proceeds.
  ///
  /// No-op when no revoke endpoint is configured (build without the
  /// `APPLE_REVOKE_ENDPOINT` dart-define) or when the signed-in user did not
  /// federate through Apple, so email/password users are never shown the Apple
  /// authorization sheet.
  Future<void> _revokeAppleGrantBestEffort() async {
    final service = _revocationService;
    if (service == null || !service.isConfigured) return;

    try {
      if (!await _isAppleLinkedUser()) return;

      // Forward the Cognito ID token — it carries an `aud` claim (the app
      // client id) that the backend's JWT authorizer validates. (Access tokens
      // omit `aud`, so the ID token is the reliable choice here.)
      final session =
          await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
      final idToken = session.userPoolTokensResult.value.idToken.raw;

      await service.revoke(authToken: idToken);
    } catch (e, stack) {
      // Best-effort: deletion proceeds regardless. Report so a systematically
      // failing revoke (e.g. a client_id mismatch) stays visible in crash
      // reporting instead of silently passing App review then failing in prod.
      log('Apple grant revocation failed (deletion continues): $e');
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: e,
          stack: stack,
          library: 'auth.appleRevocation',
        ),
      );
    }
  }

  /// Whether the signed-in Cognito user federated through Sign in with Apple.
  ///
  /// Checks the Cognito username first (federated users are named
  /// `SignInWithApple_…`) and falls back to the `identities` attribute. Any
  /// failure resolves to false, so a non-Apple user is never prompted.
  Future<bool> _isAppleLinkedUser() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      if (user.username.toLowerCase().contains('apple')) return true;
    } catch (e) {
      log('Apple-link detection via username failed: $e');
    }

    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();
      for (final attribute in attributes) {
        if (attribute.userAttributeKey.key == 'identities') {
          return attribute.value.toLowerCase().contains('apple');
        }
      }
    } catch (e) {
      log('Apple-link detection via identities failed: $e');
    }

    return false;
  }

  /// Dispose resources.
  void dispose() {
    _hubSubscription?.cancel();
    _authStateController.close();
  }
}
