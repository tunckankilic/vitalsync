/// VitalSync — Exercise Category Enum.
///
/// Major muscle group categories for exercise classification.
library;

/// Exercise category based on primary muscle groups.
enum ExerciseCategory {
  chest,
  back,
  shoulders,
  arms,
  legs,
  core,
  cardio;

  /// Convert to string for database storage.
  String toDbValue() => name;

  /// Create from database string value.
  static ExerciseCategory fromDbValue(String value) {
    return ExerciseCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExerciseCategory.cardio,
    );
  }

  /// Get localized display name.
  /// Note: Actual localization will be implemented in l10n files.
  String get displayName {
    switch (this) {
      case ExerciseCategory.chest:
        return 'Chest';
      case ExerciseCategory.back:
        return 'Back';
      case ExerciseCategory.shoulders:
        return 'Shoulders';
      case ExerciseCategory.arms:
        return 'Arms';
      case ExerciseCategory.legs:
        return 'Legs';
      case ExerciseCategory.core:
        return 'Core';
      case ExerciseCategory.cardio:
        return 'Cardio';
    }
  }
}
