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

  // Category names are not held here. They were, as a hardcoded English
  // `displayName` that nothing ever called, which made the type look
  // translated when it was not. The achievements screen labels its filter
  // chips from AppLocalizations instead.
}
