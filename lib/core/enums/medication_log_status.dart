/// VitalSync — Medication Log Status Enum.
///
/// Tracks the status of individual medication log entries.
library;

/// Status of a medication log entry.
///
/// - [taken]: User confirmed taking the medication
/// - [skipped]: User intentionally skipped
/// - [missed]: User missed the scheduled time
/// - [pending]: Scheduled but not yet time or action taken
enum MedicationLogStatus {
  taken,
  skipped,
  missed,
  pending;

  /// Convert to string for database storage.
  String toDbValue() => name;

  /// Create from database string value.
  static MedicationLogStatus fromDbValue(String value) {
    return MedicationLogStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MedicationLogStatus.pending,
    );
  }

  /// Get localized display name.
  /// Note: Actual localization will be implemented in l10n files.
  String get displayName {
    switch (this) {
      case MedicationLogStatus.taken:
        return 'Taken';
      case MedicationLogStatus.skipped:
        return 'Skipped';
      case MedicationLogStatus.missed:
        return 'Missed';
      case MedicationLogStatus.pending:
        return 'Pending';
    }
  }

  /// Whether this status counts as compliant for adherence metrics.
  bool get isCompliant => this == MedicationLogStatus.taken;
}
