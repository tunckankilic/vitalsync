/// VitalSync — Glucose Source Enum.
///
/// Identifies where a blood glucose reading came from.
library;

/// Origin of a blood glucose reading.
///
/// - [healthKit]: Imported read-only from Apple Health
/// - [manual]: Entered by the user inside VitalSync
enum GlucoseSource {
  healthKit,
  manual;

  /// Convert to string for database storage.
  String toDbValue() => name;

  /// Create from database string value.
  static GlucoseSource fromDbValue(String value) {
    return GlucoseSource.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GlucoseSource.manual,
    );
  }

  /// Whether the reading was imported from an external store.
  bool get isImported => this == GlucoseSource.healthKit;
}
