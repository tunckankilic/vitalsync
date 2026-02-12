/// VitalSync — Equipment Enum.
///
/// Types of equipment used for exercises.
library;

/// Exercise equipment types.
enum Equipment {
  barbell,
  dumbbell,
  machine,
  cable,
  bodyweight,
  kettlebell,
  other;

  /// Convert to string for database storage.
  String toDbValue() => name;

  /// Create from database string value.
  static Equipment fromDbValue(String value) {
    return Equipment.values.firstWhere(
      (e) => e.name == value,
      orElse: () => Equipment.other,
    );
  }

  /// Get localized display name.
  /// Note: Actual localization will be implemented in l10n files.
  String get displayName {
    switch (this) {
      case Equipment.barbell:
        return 'Barbell';
      case Equipment.dumbbell:
        return 'Dumbbell';
      case Equipment.machine:
        return 'Machine';
      case Equipment.cable:
        return 'Cable';
      case Equipment.bodyweight:
        return 'Bodyweight';
      case Equipment.kettlebell:
        return 'Kettlebell';
      case Equipment.other:
        return 'Other';
    }
  }
}
