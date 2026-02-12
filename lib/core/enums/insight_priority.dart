/// VitalSync — Insight Priority Enum.
///
/// Priority level for insights to determine display order.
library;

/// Priority levels for insights.
enum InsightPriority {
  low(1),
  medium(2),
  high(3),
  critical(4);

  const InsightPriority(this.value);

  final int value;

  /// Convert from integer value.
  static InsightPriority fromValue(int value) {
    return InsightPriority.values.firstWhere(
      (e) => e.value == value,
      orElse: () => InsightPriority.low,
    );
  }
}
