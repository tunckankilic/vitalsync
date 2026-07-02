/// VitalSync — Sign in with Apple token revocation service.
///
/// App Store Guideline 5.1.1(v): an app that offers Sign in with Apple **and**
/// account deletion must revoke the user's Apple token when the account is
/// deleted. The app itself cannot perform the revoke — that requires Apple's
/// private signing key, which must never ship inside the app bundle. Instead
/// the app obtains a short-lived, single-use Apple `authorizationCode` and
/// forwards it to a backend endpoint that performs the actual revoke with Apple.
///
/// Security: only the ephemeral authorization code leaves the device. The Apple
/// private key, Team ID and Key ID live solely in the backend.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:vitalsync/core/errors/exceptions.dart';

/// Obtains a fresh Apple authorization credential.
///
/// Injectable so the network path can be unit-tested without a real device or
/// the native Apple authorization sheet.
typedef AppleCredentialProvider =
    Future<AuthorizationCredentialAppleID> Function();

/// Requests backend revocation of the current user's Sign in with Apple grant.
class AppleTokenRevocationService {
  AppleTokenRevocationService({
    required String endpoint,
    http.Client? httpClient,
    AppleCredentialProvider? credentialProvider,
  }) : _endpoint = endpoint,
       _httpClient = httpClient ?? http.Client(),
       _credentialProvider = credentialProvider ?? _defaultCredentialProvider;

  /// Backend revoke endpoint URL, injected from
  /// `--dart-define=APPLE_REVOKE_ENDPOINT`. Empty when unconfigured — see
  /// [isConfigured].
  final String _endpoint;
  final http.Client _httpClient;
  final AppleCredentialProvider _credentialProvider;

  static Future<AuthorizationCredentialAppleID> _defaultCredentialProvider() {
    // Empty scopes: we only need the authorization code to revoke, not the
    // user's name/email, so this keeps the authorization prompt minimal.
    return SignInWithApple.getAppleIDCredential(scopes: const []);
  }

  /// Whether a backend endpoint has been configured. When false the entire
  /// revoke step is a no-op, so a build without the dart-define behaves exactly
  /// as before (no Apple sheet, no network call).
  bool get isConfigured => _endpoint.isNotEmpty;

  /// Revokes the current user's Sign in with Apple grant.
  ///
  /// Obtains a fresh Apple authorization code natively, then POSTs it to the
  /// backend which exchanges it for a refresh token and revokes it with Apple.
  ///
  /// [authToken] is the caller's Cognito access token, forwarded as a bearer
  /// credential so the backend (protected by a Cognito JWT authorizer) accepts
  /// the request.
  ///
  /// Throws [AppleRevocationException] on any failure. Callers run this
  /// best-effort and report — account deletion must never be blocked on it.
  Future<void> revoke({required String authToken}) async {
    if (!isConfigured) {
      throw const AppleRevocationException('Revoke endpoint not configured.');
    }

    final String authorizationCode;
    try {
      final credential = await _credentialProvider();
      authorizationCode = credential.authorizationCode;
    } catch (e) {
      throw AppleRevocationException(
        'Could not obtain Apple authorization code.',
        cause: e,
      );
    }

    if (authorizationCode.isEmpty) {
      throw const AppleRevocationException('Empty Apple authorization code.');
    }

    final http.Response response;
    try {
      response = await _httpClient.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'authorizationCode': authorizationCode}),
      );
    } catch (e) {
      throw AppleRevocationException(
        'Revoke request to backend failed.',
        cause: e,
      );
    }

    if (response.statusCode != 200) {
      throw AppleRevocationException(
        'Backend revoke returned HTTP ${response.statusCode}.',
      );
    }
  }
}
