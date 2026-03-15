/// VitalSync — Insight Rule Interface (Strategy Pattern).
///
/// Each insight rule can be extracted into a separate class that
/// implements this interface, enabling:
/// - Independent testing per rule
/// - Easy addition of new rules without touching InsightEngine
/// - Rule-level feature flags / A/B testing
///
/// Future migration path:
/// 1. Extract each `_check*()` method in InsightEngine into its own class
/// 2. Register rules via DI (GetIt) as a `List<InsightRule>`
/// 3. InsightEngine iterates over rules in `generateAllInsights()`
library;

import 'package:vitalsync/domain/entities/insights/insight.dart';

/// Strategy interface for a single insight rule.
///
/// Each rule encapsulates:
/// - Its unique [ruleId] for duplicate prevention
/// - The [evaluate] logic that returns zero or more insights
abstract class InsightRule {
  /// Unique identifier used for duplicate prevention.
  String get ruleId;

  /// Human-readable name for logging/debugging.
  String get displayName;

  /// Evaluates the rule and returns generated insights.
  ///
  /// Returns an empty list if conditions are not met.
  /// Implementations should handle their own error cases gracefully.
  Future<List<Insight>> evaluate();
}
