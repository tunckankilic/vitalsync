/// VitalSync — Meal Context Enum.
///
/// Optional label describing when a glucose reading was taken relative
/// to a meal. Purely descriptive — it carries no interpretation of the
/// reading itself.
library;

/// When a glucose reading was taken relative to eating.
///
/// - [fasting]: Taken after an overnight fast
/// - [preMeal]: Taken shortly before eating
/// - [postMeal]: Taken after eating
/// - [other]: None of the above / unspecified context
enum MealContext {
  fasting,
  preMeal,
  postMeal,
  other;

  /// Convert to string for database storage.
  String toDbValue() => name;

  /// Create from database string value.
  static MealContext fromDbValue(String value) {
    return MealContext.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MealContext.other,
    );
  }
}
