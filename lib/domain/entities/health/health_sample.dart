import '../../../core/enums/health_data_source_kind.dart';
import '../../../core/enums/health_sample_type.dart';

/// An activity or sleep sample imported from the platform health store.
///
/// Local mirror only — health samples are not pushed to the cloud, so this
/// entity carries no sync status.
class HealthSample {
  const HealthSample({
    required this.id,
    required this.type,
    required this.startAt,
    required this.value,
    required this.unit,
    required this.source,
    required this.lastModifiedAt,
    required this.createdAt,
    this.endAt,
    this.externalId,
    this.metadata,
  });
  final int id;
  final HealthSampleType type;
  final DateTime startAt;
  final DateTime? endAt;
  final double value;
  final String unit;
  final HealthDataSourceKind source;
  final String? externalId;
  final String? metadata;
  final DateTime lastModifiedAt;
  final DateTime createdAt;

  HealthSample copyWith({
    int? id,
    HealthSampleType? type,
    DateTime? startAt,
    DateTime? endAt,
    double? value,
    String? unit,
    HealthDataSourceKind? source,
    String? externalId,
    String? metadata,
    DateTime? lastModifiedAt,
    DateTime? createdAt,
  }) {
    return HealthSample(
      id: id ?? this.id,
      type: type ?? this.type,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      source: source ?? this.source,
      externalId: externalId ?? this.externalId,
      metadata: metadata ?? this.metadata,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is HealthSample &&
        other.id == id &&
        other.type == type &&
        other.startAt == startAt &&
        other.endAt == endAt &&
        other.value == value &&
        other.unit == unit &&
        other.source == source &&
        other.externalId == externalId &&
        other.metadata == metadata &&
        other.lastModifiedAt == lastModifiedAt &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        type.hashCode ^
        startAt.hashCode ^
        endAt.hashCode ^
        value.hashCode ^
        unit.hashCode ^
        source.hashCode ^
        externalId.hashCode ^
        metadata.hashCode ^
        lastModifiedAt.hashCode ^
        createdAt.hashCode;
  }

  @override
  String toString() {
    return 'HealthSample(id: $id, type: $type, startAt: $startAt, endAt: $endAt, value: $value, unit: $unit, source: $source, externalId: $externalId, metadata: $metadata, lastModifiedAt: $lastModifiedAt, createdAt: $createdAt)';
  }
}
