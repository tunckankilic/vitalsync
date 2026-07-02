/// VitalSync — GDPR Compliance Manager.
///
/// Consent management (analytics, health data, fitness data, cloud backup).
/// Data export (JSON format for portability).
/// Right to deletion (account + all local data + cloud data).
/// Privacy policy versioning and consent logging with timestamps.
/// Analytics consent check helper.
///
/// Cloud provider abstracted via [AuthRepository] and [CloudSyncClient].
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/local/database.dart';
import '../../domain/models/app_user.dart';
import '../../domain/repositories/shared/auth_repository.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';
import '../sync/cloud_sync_client.dart';
import '../sync/sync_service.dart';

/// GDPR Compliance Manager for VitalSync.
///
/// Handles all GDPR-related functionality including consent management,
/// data portability, and the right to be forgotten.
class GDPRManager {
  GDPRManager({
    required SharedPreferences prefs,
    required CloudSyncClient cloudClient,
    required AuthRepository auth,
    required AppDatabase database,
  }) : _prefs = prefs,
       _cloudClient = cloudClient,
       _auth = auth,
       _database = database;
  final SharedPreferences _prefs;
  final CloudSyncClient _cloudClient;
  final AuthRepository _auth;
  final AppDatabase _database;

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
      throw StateError('No authenticated user for data export');
    }

    final databaseExport = await _database.exportAllData();

    final exportData = <String, dynamic>{
      'export_timestamp': DateTime.now().toIso8601String(),
      'policy_version': getCurrentPolicyVersion(),
      'auth_user': _userToExportMap(user),
      'consents': getAllConsents(),
      'consent_history': await _getConsentHistory(),
      'privacy_policy': {
        'accepted_version': getAcceptedPolicyVersion(),
        'acceptance_timestamp': getPolicyAcceptanceTimestamp()
            ?.toIso8601String(),
        'current_version': getCurrentPolicyVersion(),
      },
      ...databaseExport,
    };

    return json.encode(exportData);
  }

  /// Converts an [AppUser] to an export-friendly map.
  Map<String, dynamic> _userToExportMap(AppUser user) {
    return {
      'uid': user.id,
      'email': user.email,
      'email_verified': user.emailVerified,
      'created_at': user.createdAt?.toIso8601String(),
      'last_sign_in': user.lastSignInAt?.toIso8601String(),
    };
  }

  // DATA DELETION (Right to be Forgotten)

  /// Deletes all user data, locally and in the cloud, then deletes the account.
  ///
  /// This fulfills the GDPR right to erasure (Article 17) and Apple's in-app
  /// account-deletion requirement (App Store Guideline 5.1.1(v)).
  ///
  /// Order matters and is deliberate:
  /// 1. Delete the cloud (DynamoDB) data **first**, while the auth session is
  ///    still valid. If this fails (typically: offline / server error) the
  ///    whole operation aborts with an [AccountDeletionException] and nothing
  ///    local is touched — we must never delete the account while server-side
  ///    health data remains, because that orphans the data with no way to
  ///    retry. Callers are expected to require connectivity up front and to
  ///    surface this failure to the user.
  /// 2. Clear the local Drift database.
  /// 3. Clear all SharedPreferences (consents, settings, onboarding flag).
  /// 4. Delete the auth account **last** — this invalidates the session and
  ///    fires the `userDeleted` event that drives the app back to login.
  Future<void> deleteAllUserData() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AccountDeletionException(
        'No authenticated user for data deletion',
      );
    }

    // Step 1: Delete cloud user data (must succeed before anything destructive).
    // Mirror SyncService's canonical table list (plus the optional insights
    // collection) so the erasure set can never silently drift behind what is
    // actually synced. The previous hardcoded copy was missing workout_sets and
    // personal_records, orphaning that health data in the cloud after deletion.
    const collections = [...SyncService.tablesToSync, 'insights'];
    try {
      await _cloudClient.deleteAllUserData(
        userId: user.id,
        collections: collections,
      );
    } catch (e) {
      throw AccountDeletionException(
        'Cloud data deletion failed; account deletion aborted.',
        cause: e,
      );
    }

    // Step 2: Clear the local database.
    await _database.deleteAllData();

    // Step 3: Clear SharedPreferences.
    await _prefs.clear();

    // Step 4: Delete the auth account (must be last).
    await _auth.deleteAccount();
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
