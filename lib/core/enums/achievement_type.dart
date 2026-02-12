/// VitalSync — Achievement Type Enum.
///
/// Categories of achievements users can unlock.
library;

/// Achievement type categories.
///
/// Includes both fitness and health-related achievements,
/// plus cross-module achievements for balanced wellness.
enum AchievementType {
  streak,
  volume,
  workouts,
  pr,
  medicationCompliance,
  consistency;

  /// Convert to string for database storage.
  String toDbValue() => name;

  /// Create from database string value.
  static AchievementType fromDbValue(String value) {
    return AchievementType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AchievementType.consistency,
    );
  }

  /// Get localized display name.
  /// Note: Actual localization will be implemented in l10n files.
  String get displayName {
    switch (this) {
      case AchievementType.streak:
        return 'Workout Streak';
      case AchievementType.volume:
        return 'Total Volume';
      case AchievementType.workouts:
        return 'Workout Count';
      case AchievementType.pr:
        return 'Personal Records';
      case AchievementType.medicationCompliance:
        return 'Medication Adherence';
      case AchievementType.consistency:
        return 'Consistency';
    }
  }
}
