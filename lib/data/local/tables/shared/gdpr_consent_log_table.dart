/// VitalSync — GDPR Consent Log Table (Shared).
///
/// Tracks user consent history for GDPR compliance.
library;

import 'package:drift/drift.dart';

/// GDPR consent log table.
///
/// Maintains an audit trail of all consent decisions made by the user.
/// Each consent type (analytics, health data, etc.) can have multiple
/// log entries as the user updates their preferences or policy versions change.
@DataClassName('GdprConsentLogData')
class GdprConsentLogs extends Table {
  /// Primary key.
  IntColumn get id => integer().autoIncrement()();

  /// Type of consent being tracked.
  /// Examples: 'analytics', 'health_data', 'fitness_data', 'cloud_backup'
  TextColumn get consentType => text()();

  /// Whether consent was granted (true) or revoked (false).
  BoolColumn get granted => boolean()();

  /// Privacy policy version this consent applies to.
  /// When policy updates, users may need to re-consent.
  TextColumn get policyVersion => text()();

  /// Timestamp when this consent decision was made.
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
}
