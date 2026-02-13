/// Trend direction for week-over-week comparisons.
enum TrendDirection {
  /// Value increased compared to previous week (↑).
  up,

  /// Value decreased compared to previous week (↓).
  down,

  /// Value remained approximately the same (→).
  same,
}

extension TrendDirectionX on TrendDirection {
  String get displayName {
    switch (this) {
      case TrendDirection.up:
        return '↑';
      case TrendDirection.down:
        return '↓';
      case TrendDirection.same:
        return '→';
    }
  }
}
