/// VitalSync — Insight Type Enum.
///
/// Types of insights the rule-based engine can generate.
library;

/// Insight type classification.
///
/// - [correlation]: Relationship between two data points
/// - [trend]: Pattern over time
/// - [anomaly]: Unusual deviation from normal
/// - [suggestion]: Actionable recommendation
/// - [milestone]: Achievement or goal reached
enum InsightType {
  correlation,
  trend,
  anomaly,
  suggestion,
  milestone;

  /// Convert to string for database storage.
  String toDbValue() => name;

  /// Create from database string value.
  static InsightType fromDbValue(String value) {
    return InsightType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => InsightType.suggestion,
    );
  }

  /// Get localized display name.
  /// Note: Actual localization will be implemented in l10n files.
  String get displayName {
    switch (this) {
      case InsightType.correlation:
        return 'Correlation';
      case InsightType.trend:
        return 'Trend';
      case InsightType.anomaly:
        return 'Anomaly';
      case InsightType.suggestion:
        return 'Suggestion';
      case InsightType.milestone:
        return 'Milestone';
    }
  }
}
