/// VitalSync — Biometric Authentication Service.
///
/// Provides biometric authentication (Face ID / Fingerprint) using local_auth.
/// Falls back gracefully on unsupported devices.
library;

import 'dart:developer' show log;

import 'package:local_auth/local_auth.dart';

/// Service for biometric authentication.
class BiometricService {
  BiometricService() : _auth = LocalAuthentication();

  final LocalAuthentication _auth;

  /// Check if biometric authentication is available on this device.
  Future<bool> isAvailable() async {
    try {
      final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } catch (e, st) {
      log('BiometricService.isAvailable failed', error: e, stackTrace: st);
      return false;
    }
  }

  /// Get available biometric types (fingerprint, face, iris).
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e, st) {
      log(
        'BiometricService.getAvailableBiometrics failed',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  /// Authenticate using biometrics.
  /// Returns true if authentication succeeded.
  Future<bool> authenticate({String reason = 'Authenticate to sign in'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
      );
    } catch (e, st) {
      log('BiometricService.authenticate failed', error: e, stackTrace: st);
      return false;
    }
  }
}
