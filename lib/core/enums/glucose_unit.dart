/// VitalSync — Glucose Unit Enum.
///
/// Display unit for a blood glucose measurement. Storage is always mg/dL —
/// this only converts for entry and display, and carries no interpretation
/// of the value.
library;

/// Unit a glucose value is shown or entered in.
///
/// - [mgPerDl]: milligrams per decilitre, the storage unit
/// - [mmolPerL]: millimoles per litre
enum GlucoseUnit {
  mgPerDl,
  mmolPerL;

  /// Molar conversion factor for glucose (molar mass 180.156 g/mol).
  static const double _mmolPerLPerMgPerDl = 18.0182;

  /// Suffix shown next to a value.
  String get label => switch (this) {
    GlucoseUnit.mgPerDl => 'mg/dL',
    GlucoseUnit.mmolPerL => 'mmol/L',
  };

  /// Decimal places a value is displayed with in this unit.
  int get decimals => switch (this) {
    GlucoseUnit.mgPerDl => 0,
    GlucoseUnit.mmolPerL => 1,
  };

  /// Converts a stored mg/dL value into this unit.
  double fromMgDl(double valueMgDl) => switch (this) {
    GlucoseUnit.mgPerDl => valueMgDl,
    GlucoseUnit.mmolPerL => valueMgDl / _mmolPerLPerMgPerDl,
  };

  /// Converts a value entered in this unit into mg/dL for storage.
  double toMgDl(double value) => switch (this) {
    GlucoseUnit.mgPerDl => value,
    GlucoseUnit.mmolPerL => value * _mmolPerLPerMgPerDl,
  };

  /// Formats a stored mg/dL value for display in this unit, without a suffix.
  String formatMgDl(double valueMgDl) =>
      fromMgDl(valueMgDl).toStringAsFixed(decimals);

  /// Formats a stored mg/dL value for display in this unit, with the suffix.
  String formatMgDlWithLabel(double valueMgDl) =>
      '${formatMgDl(valueMgDl)} $label';
}
