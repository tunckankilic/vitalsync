/// VitalSync — Gender Enum.
///
/// User gender options with privacy-conscious choices.
library;

/// User gender options.
///
/// Includes privacy option to allow users not to disclose.
enum Gender {
  male,
  female,
  other,
  preferNotToSay;

  /// Convert to string for database storage.
  String toDbValue() => name;

  /// Create from database string value.
  static Gender fromDbValue(String value) {
    return Gender.values.firstWhere(
      (e) => e.name == value,
      orElse: () => Gender.preferNotToSay,
    );
  }

  /// Get localized display name.
  /// Note: Actual localization will be implemented in l10n files.
  String get displayName {
    switch (this) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.other:
        return 'Other';
      case Gender.preferNotToSay:
        return 'Prefer not to say';
    }
  }
}
