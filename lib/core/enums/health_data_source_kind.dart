/// VitalSync — Health Data Source Kind Enum.
///
/// Abstracts the origin of an imported health sample so a second platform
/// store (e.g. Health Connect) can be added later without a schema change.
library;

/// Origin of a health sample.
///
/// - [healthKit]: Read from Apple Health
/// - [manual]: Entered by the user inside VitalSync
enum HealthDataSourceKind {
  healthKit,
  manual;

  /// Convert to string for database storage.
  String toDbValue() => name;

  /// Create from database string value.
  static HealthDataSourceKind fromDbValue(String value) {
    return HealthDataSourceKind.values.firstWhere(
      (e) => e.name == value,
      orElse: () => HealthDataSourceKind.manual,
    );
  }
}
