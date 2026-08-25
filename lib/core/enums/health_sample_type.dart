/// VitalSync — Health Sample Type Enum.
///
/// The four Apple Health quantity/category types VitalSync reads.
/// Deliberately limited — no additional types are read in this version.
library;

/// Type of an imported health sample.
///
/// - [steps]: Step count over an interval
/// - [activeEnergy]: Active energy burned over an interval
/// - [workout]: A recorded exercise session
/// - [sleep]: A sleep interval
enum HealthSampleType {
  steps,
  activeEnergy,
  workout,
  sleep;

  /// Convert to string for database storage.
  String toDbValue() => name;

  /// Create from database string value.
  static HealthSampleType fromDbValue(String value) {
    return HealthSampleType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => HealthSampleType.steps,
    );
  }
}
