/// VitalSync — Medication Frequency Enum.
///
/// Defines how often a medication should be taken.
library;

/// Medication frequency options.
///
/// Covers common prescription frequencies from daily to as-needed.
enum MedicationFrequency {
  daily,
  twiceDaily,
  threeTimesDaily,
  weekly,
  monthly,
  asNeeded;

  /// Convert to string for database storage.
  String toDbValue() => name;

  /// Create from database string value.
  static MedicationFrequency fromDbValue(String value) {
    return MedicationFrequency.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MedicationFrequency.daily,
    );
  }

  /// Get localized display name.
  /// Note: Actual localization will be implemented in l10n files.
  String get displayName {
    switch (this) {
      case MedicationFrequency.daily:
        return 'Daily';
      case MedicationFrequency.twiceDaily:
        return 'Twice Daily';
      case MedicationFrequency.threeTimesDaily:
        return 'Three Times Daily';
      case MedicationFrequency.weekly:
        return 'Weekly';
      case MedicationFrequency.monthly:
        return 'Monthly';
      case MedicationFrequency.asNeeded:
        return 'As Needed';
    }
  }
}
