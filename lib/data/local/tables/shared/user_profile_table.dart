/// VitalSync — User Profile Table (Shared).
///
/// Stores user profile data including GDPR consent versioning.
library;

import 'package:drift/drift.dart';

import '../../../../core/enums/gender.dart';

/// User profile table storing personal information and GDPR consent.
///
/// This is the central user table that contains demographic information,
/// emergency contacts, and GDPR consent tracking.
/// The gdprConsentVersion and gdprConsentDate fields are mandatory
/// to ensure GDPR compliance.
@DataClassName('UserProfileData')
class UserProfiles extends Table {
  /// Primary key.
  IntColumn get id => integer().autoIncrement()();

  /// Firebase Authentication UID.
  /// Must be unique - each Firebase user has exactly one profile.
  TextColumn get firebaseUid => text().unique()();

  /// User's display name.
  TextColumn get name => text()();

  /// Date of birth (optional).
  /// Can be used for age-related insights and recommendations.
  DateTimeColumn get birthDate => dateTime().nullable()();

  /// User's gender (optional).
  /// Stored as string, converted to/from Gender enum.
  TextColumn get gender =>
      textEnum<Gender>().withDefault(const Constant('preferNotToSay'))();

  /// User's preferred locale (e.g., 'en', 'tr', 'de').
  /// Defaults to 'en'.
  TextColumn get locale => text().withDefault(const Constant('en'))();

  /// Emergency contact name (optional).
  TextColumn get emergencyContact => text().nullable()();

  /// Emergency contact phone number (optional).
  TextColumn get emergencyPhone => text().nullable()();

  /// GDPR consent policy version that user agreed to.
  /// Required field - user must accept privacy policy to use the app.
  TextColumn get gdprConsentVersion => text()();

  /// Date when user accepted the GDPR consent.
  /// Required field for compliance tracking.
  DateTimeColumn get gdprConsentDate => dateTime()();

  /// Profile creation timestamp.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Last profile update timestamp.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
