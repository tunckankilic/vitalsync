/// VitalSync — Health Data Source (platform-agnostic contract).
///
/// The app reads from a platform health store through this interface only.
/// Apple Health is the sole implementation in 2.0, but Google Health Connect
/// must be addable later as a single new class — so **no HealthKit type may
/// appear in this file or cross this boundary.**
///
/// Read-only by contract: there is no write method, and no implementation may
/// request write authorization.
library;

/// A kind of sample VitalSync is allowed to read.
///
/// Deliberately limited to five. Adding a kind here means asking the user for
/// another health permission, which is a product decision, not a refactor.
enum HealthSampleKind {
  bloodGlucose,
  steps,
  activeEnergy,
  workout,
  sleep;

  /// Whether the kind is stored as a glucose reading rather than a
  /// generic health sample.
  bool get isGlucose => this == HealthSampleKind.bloodGlucose;
}

/// One sample read from a platform health store.
///
/// Platform-neutral on purpose: [externalId] is whatever stable identifier the
/// store exposes (a HealthKit sample UUID today) and is used for deduplication,
/// while [metadata] carries kind-specific extras as a plain map.
class HealthSampleDto {
  const HealthSampleDto({
    required this.kind,
    required this.startAt,
    required this.value,
    required this.unit,
    this.endAt,
    this.externalId,
    this.metadata,
  });

  final HealthSampleKind kind;
  final DateTime startAt;
  final DateTime? endAt;
  final double value;
  final String unit;
  final String? externalId;
  final Map<String, dynamic>? metadata;

  @override
  String toString() {
    // Deliberately omits [value]: this string can reach logs and crash
    // reports, and a glucose reading must not appear in either.
    return 'HealthSampleDto(kind: $kind, startAt: $startAt, endAt: $endAt, '
        'unit: $unit, externalId: $externalId)';
  }
}

/// Read-only access to a platform health store.
abstract class HealthDataSource {
  /// Asks the platform for **read** access to the supported kinds.
  ///
  /// Returns whether the request completed with access granted. The platform
  /// may grant a subset; use [readSamples], which skips what it cannot read.
  Future<bool> requestPermissions();

  /// Whether the app currently holds read access.
  ///
  /// On iOS this is best-effort: HealthKit deliberately does not reveal read
  /// denials, so a `false` here means "not known to be authorized", not
  /// "denied".
  Future<bool> isAuthorized();

  /// Reads samples of [kinds] recorded at or after [since].
  ///
  /// Kinds the platform refuses are skipped rather than raising, so a user who
  /// granted only glucose still gets a working import. Throws
  /// [HealthDataException] only when the read fails as a whole.
  Future<List<HealthSampleDto>> readSamples({
    required List<HealthSampleKind> kinds,
    required DateTime since,
  });

  /// Releases the app's access to the platform health store.
  Future<void> disconnect();
}
