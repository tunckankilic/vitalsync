/// VitalSync — Insight Category Enum.
///
/// Categorizes insights by module or cross-module analysis.
library;

/// Insight category classification.
///
/// - [health]: Health module specific (medications, symptoms)
/// - [fitness]: Fitness module specific (workouts, progress)
/// - [crossModule]: Cross-module analysis (health + fitness correlation)
enum InsightCategory {
  health,
  fitness,
  crossModule;

  /// Convert to string for database storage.
  String toDbValue() => name;

  /// Create from database string value.
  static InsightCategory fromDbValue(String value) {
    return InsightCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => InsightCategory.crossModule,
    );
  }

  /// Get localized display name.
  /// Note: Actual localization will be implemented in l10n files.
  String get displayName {
    switch (this) {
      case InsightCategory.health:
        return 'Health';
      case InsightCategory.fitness:
        return 'Fitness';
      case InsightCategory.crossModule:
        return 'Overall Wellness';
    }
  }
}
