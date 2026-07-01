import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:vitalsync/core/auth/apple_token_revocation_service.dart';
import 'package:vitalsync/core/errors/exceptions.dart';

AuthorizationCredentialAppleID _credential(String code) {
  return AuthorizationCredentialAppleID(
    userIdentifier: 'user-123',
    givenName: null,
    familyName: null,
    authorizationCode: code,
    email: null,
    identityToken: null,
    state: null,
  );
}

void main() {
  group('AppleTokenRevocationService', () {
    test('isConfigured reflects whether an endpoint was provided', () {
      expect(AppleTokenRevocationService(endpoint: '').isConfigured, isFalse);
      expect(
        AppleTokenRevocationService(
          endpoint: 'https://example.com/revoke',
        ).isConfigured,
        isTrue,
      );
    });

    test('revoke throws when unconfigured (no network / Apple sheet)', () async {
      final service = AppleTokenRevocationService(endpoint: '');
      await expectLater(
        service.revoke(authToken: 'token'),
        throwsA(isA<AppleRevocationException>()),
      );
    });

    test('revoke posts the authorization code with a bearer token', () async {
      late http.Request captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response('{"revoked":true}', 200);
      });

      final service = AppleTokenRevocationService(
        endpoint: 'https://example.com/revoke',
        httpClient: client,
        credentialProvider: () async => _credential('apple-auth-code'),
      );

      await service.revoke(authToken: 'id-token-abc');

      expect(captured.method, 'POST');
      expect(captured.url.toString(), 'https://example.com/revoke');
      expect(captured.headers['Authorization'], 'Bearer id-token-abc');
      expect(jsonDecode(captured.body), {
        'authorizationCode': 'apple-auth-code',
      });
    });

    test('revoke throws on a non-200 backend response', () async {
      final client = MockClient((request) async => http.Response('nope', 500));
      final service = AppleTokenRevocationService(
        endpoint: 'https://example.com/revoke',
        httpClient: client,
        credentialProvider: () async => _credential('code'),
      );

      await expectLater(
        service.revoke(authToken: 'token'),
        throwsA(isA<AppleRevocationException>()),
      );
    });

    test('revoke wraps a credential-provider failure (e.g. user cancel)', () async {
      final client = MockClient((request) async => http.Response('{}', 200));
      final service = AppleTokenRevocationService(
        endpoint: 'https://example.com/revoke',
        httpClient: client,
        credentialProvider: () async => throw Exception('cancelled'),
      );

      await expectLater(
        service.revoke(authToken: 'token'),
        throwsA(isA<AppleRevocationException>()),
      );
    });

    test('revoke rejects an empty authorization code', () async {
      final client = MockClient((request) async => http.Response('{}', 200));
      final service = AppleTokenRevocationService(
        endpoint: 'https://example.com/revoke',
        httpClient: client,
        credentialProvider: () async => _credential(''),
      );

      await expectLater(
        service.revoke(authToken: 'token'),
        throwsA(isA<AppleRevocationException>()),
      );
    });
  });
}
