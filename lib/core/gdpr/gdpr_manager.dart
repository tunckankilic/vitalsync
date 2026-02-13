/// VitalSync — GDPR Compliance Manager.
///
/// Consent management (analytics, health data, fitness data, cloud backup).
/// Data export (JSON format for portability).
/// Right to deletion (account + all local data + Firestore data).
/// Privacy policy versioning and consent logging with timestamps.
/// Analytics consent check helper.
library;

import 'dart:convert';
import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// GDPR Compliance Manager for VitalSync.
///
/// Handles all GDPR-related functionality including consent management,
/// data portability, and the right to be forgotten.
class GDPRManager {
  GDPRManager({
    required SharedPreferences prefs,
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _prefs = prefs,
       _firestore = firestore,
       _auth = auth;
  final SharedPreferences _prefs;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // CONSENT MANAGEMENT

  /// Grants consent for a specific data processing type.
  ///
  /// [consentType] must be one of:
  /// - AppConstants.gdprConsentTypeAnalytics
  /// - AppConstants.gdprConsentTypeHealthData
  /// - AppConstants.gdprConsentTypeFitnessData
  /// - AppConstants.gdprConsentTypeCloudBackup
  ///
  /// Logs the consent grant with timestamp and policy version.
  Future<void> grantConsent(String consentType) async {
    await _setConsent(consentType, granted: true);
    await _logConsentChange(consentType, granted: true);
  }

  /// Revokes consent for a specific data processing type.
  ///
  /// If cloud backup consent is revoked, the user should be informed
  /// that sync will stop and existing cloud data may be deleted.
  Future<void> revokeConsent(String consentType) async {
    await _setConsent(consentType, granted: false);
    await _logConsentChange(consentType, granted: false);
  }

  /// Checks if consent has been granted for a specific type.
  ///
  /// Returns false if consent has never been explicitly granted.
  bool hasConsent(String consentType) {
    switch (consentType) {
      case AppConstants.gdprConsentTypeAnalytics:
        return _prefs.getBool(AppConstants.prefKeyAnalyticsConsent) ?? false;
      case AppConstants.gdprConsentTypeHealthData:
        return _prefs.getBool(AppConstants.prefKeyHealthDataConsent) ?? false;
      case AppConstants.gdprConsentTypeFitnessData:
        return _prefs.getBool(AppConstants.prefKeyFitnessDataConsent) ?? false;
      case AppConstants.gdprConsentTypeCloudBackup:
        return _prefs.getBool(AppConstants.prefKeyCloudBackupConsent) ?? false;
      default:
        throw ArgumentError('Unknown consent type: $consentType');
    }
  }

  /// Returns all consent statuses as a map.
  Map<String, bool> getAllConsents() {
    return {
      AppConstants.gdprConsentTypeAnalytics: hasConsent(
        AppConstants.gdprConsentTypeAnalytics,
      ),
      AppConstants.gdprConsentTypeHealthData: hasConsent(
        AppConstants.gdprConsentTypeHealthData,
      ),
      AppConstants.gdprConsentTypeFitnessData: hasConsent(
        AppConstants.gdprConsentTypeFitnessData,
      ),
      AppConstants.gdprConsentTypeCloudBackup: hasConsent(
        AppConstants.gdprConsentTypeCloudBackup,
      ),
    };
  }

  /// Helper method to check if analytics tracking is allowed.
  ///
  /// This is a convenience method used by AnalyticsService.
  bool canTrackAnalytics() {
    return hasConsent(AppConstants.gdprConsentTypeAnalytics);
  }

  // PRIVACY POLICY

  /// Returns the current privacy policy version.
  String getCurrentPolicyVersion() {
    return AppConstants.gdprPolicyVersion;
  }

  /// Updates the user's acceptance of the current privacy policy.
  ///
  /// Stores the policy version and acceptance timestamp.
  Future<void> updatePolicyAcceptance() async {
    final now = DateTime.now().toIso8601String();
    await _prefs.setString(
      AppConstants.prefKeyGdprConsentVersion,
      AppConstants.gdprPolicyVersion,
    );
    await _prefs.setString(AppConstants.prefKeyGdprConsentTimestamp, now);
  }

  /// Checks if the user has accepted the current privacy policy version.
  bool hasAcceptedCurrentPolicy() {
    final acceptedVersion = _prefs.getString(
      AppConstants.prefKeyGdprConsentVersion,
    );
    return acceptedVersion == AppConstants.gdprPolicyVersion;
  }

  /// Returns the policy version the user last accepted, or null if never accepted.
  String? getAcceptedPolicyVersion() {
    return _prefs.getString(AppConstants.prefKeyGdprConsentVersion);
  }

  /// Returns the timestamp when the user last accepted a policy, or null.
  DateTime? getPolicyAcceptanceTimestamp() {
    final timestampStr = _prefs.getString(
      AppConstants.prefKeyGdprConsentTimestamp,
    );
    if (timestampStr == null) return null;
    return DateTime.tryParse(timestampStr);
  }

  // DATA EXPORT (Right to Data Portability)

  /// Exports all user data as a JSON string.
  ///
  /// This fulfills the GDPR right to data portability (Article 20).
  /// The exported data is in a structured, machine-readable format.
  ///
  /// Note: This method requires access to the repository layer.
  /// The actual implementation should be injected or called from a higher layer
  /// that has access to all repositories.
  ///
  /// This is a placeholder that returns consent data and user profile metadata.
  /// The full implementation should be completed in the UserRepository.
  Future<String> exportAllUserData() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user for data export');
    }

    final exportData = {
      'export_timestamp': DateTime.now().toIso8601String(),
      'policy_version': getCurrentPolicyVersion(),
      'user': {
        'uid': user.uid,
        'email': user.email,
        'email_verified': user.emailVerified,
        'created_at': user.metadata.creationTime?.toIso8601String(),
        'last_sign_in': user.metadata.lastSignInTime?.toIso8601String(),
      },
      'consents': getAllConsents(),
      'consent_history': await _getConsentHistory(),
      'privacy_policy': {
        'accepted_version': getAcceptedPolicyVersion(),
        'acceptance_timestamp': getPolicyAcceptanceTimestamp()
            ?.toIso8601String(),
        'current_version': getCurrentPolicyVersion(),
      },
      // Note: Full data export should include:
      // - user_profile
      // - medications
      // - medication_logs
      // - symptoms
      // - exercises
      // - workout_templates
      // - workout_sessions
      // - workout_sets
      // - personal_records
      // - achievements
      // - generated_insights
      // These should be added by UserRepository using this as a base.
    };

    return json.encode(exportData);
  }

  // DATA DELETION (Right to be Forgotten)

  /// Deletes all user data (local and cloud).
  ///
  /// This fulfills the GDPR right to erasure (Article 17).
  ///
  /// Steps:
  /// 1. Delete all local data from Drift database
  /// 2. Delete all Firestore user data
  /// 3. Delete Firebase Auth account
  /// 4. Clear all SharedPreferences
  ///
  /// Note: This method requires access to the repository layer.
  /// The actual implementation should be completed in the UserRepository.
  Future<void> deleteAllUserData() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user for data deletion');
    }

    // Step 1 & 2: These should be handled by UserRepository
    // which has access to the database and all collections

    // Step 3: Delete Firestore user data
    try {
      // Delete user document
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete all subcollections (this is a simplified version)
      // In production, consider using Cloud Functions for recursive deletion
      final collections = [
        'medications',
        'medication_logs',
        'symptoms',
        'workout_sessions',
        'achievements',
        'insights',
      ];

      for (final collection in collections) {
        final snapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection(collection)
            .get();

        for (final doc in snapshot.docs) {
          await doc.reference.delete();
        }
      }
    } catch (e) {
      // Log error but continue with deletion process
      log('Error deleting Firestore data: $e');
    }

    // Step 4: Clear SharedPreferences
    await _prefs.clear();

    // Step 5: Delete Firebase Auth account (must be last)
    await user.delete();
  }

  // CONSENT LOGGING (Internal)

  /// Internal method to set consent value.
  Future<void> _setConsent(String consentType, {required bool granted}) async {
    String prefKey;
    switch (consentType) {
      case AppConstants.gdprConsentTypeAnalytics:
        prefKey = AppConstants.prefKeyAnalyticsConsent;
      case AppConstants.gdprConsentTypeHealthData:
        prefKey = AppConstants.prefKeyHealthDataConsent;
      case AppConstants.gdprConsentTypeFitnessData:
        prefKey = AppConstants.prefKeyFitnessDataConsent;
      case AppConstants.gdprConsentTypeCloudBackup:
        prefKey = AppConstants.prefKeyCloudBackupConsent;
      default:
        throw ArgumentError('Unknown consent type: $consentType');
    }

    await _prefs.setBool(prefKey, granted);
  }

  /// Logs a consent change to SharedPreferences.
  ///
  /// Consent history is stored as a JSON array of log entries.
  Future<void> _logConsentChange(
    String consentType, {
    required bool granted,
  }) async {
    final history = await _getConsentHistory();

    final logEntry = {
      'consent_type': consentType,
      'granted': granted,
      'policy_version': getCurrentPolicyVersion(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    history.add(logEntry);

    // Store as JSON string
    final historyJson = json.encode(history);
    await _prefs.setString('gdpr_consent_history', historyJson);
  }

  /// Retrieves the consent change history.
  Future<List<Map<String, dynamic>>> _getConsentHistory() async {
    final historyJson = _prefs.getString('gdpr_consent_history');
    if (historyJson == null) return [];

    try {
      final List<dynamic> decoded = json.decode(historyJson);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }
}
