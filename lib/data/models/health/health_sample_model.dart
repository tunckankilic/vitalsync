import 'package:drift/drift.dart';

import '../../../core/enums/health_data_source_kind.dart';
import '../../../core/enums/health_sample_type.dart';
import '../../../domain/entities/health/health_sample.dart';
import '../../local/database.dart';

/// Health Sample Model.
class HealthSampleModel extends HealthSample {
  const HealthSampleModel({
    required super.id,
    required super.type,
    required super.startAt,
    required super.value,
    required super.unit,
    required super.source,
    required super.lastModifiedAt,
    required super.createdAt,
    super.endAt,
    super.externalId,
    super.metadata,
  });

  factory HealthSampleModel.fromJson(Map<String, dynamic> json) {
    return HealthSampleModel(
      id: json['id'] as int? ?? 0,
      type: HealthSampleType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => HealthSampleType.steps,
      ),
      startAt: DateTime.parse(json['startAt'] as String),
      endAt: json['endAt'] != null
          ? DateTime.parse(json['endAt'] as String)
          : null,
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String,
      source: HealthDataSourceKind.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => HealthDataSourceKind.healthKit,
      ),
      externalId: json['externalId'] as String?,
      metadata: json['metadata'] as String?,
      lastModifiedAt: DateTime.parse(json['lastModifiedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  factory HealthSampleModel.fromEntity(HealthSample entity) {
    return HealthSampleModel(
      id: entity.id,
      type: entity.type,
      startAt: entity.startAt,
      endAt: entity.endAt,
      value: entity.value,
      unit: entity.unit,
      source: entity.source,
      externalId: entity.externalId,
      metadata: entity.metadata,
      lastModifiedAt: entity.lastModifiedAt,
      createdAt: entity.createdAt,
    );
  }

  factory HealthSampleModel.fromDrift(HealthSampleData data) {
    return HealthSampleModel(
      id: data.id,
      type: data.type,
      startAt: data.startAt,
      endAt: data.endAt,
      value: data.value,
      unit: data.unit,
      source: data.source,
      externalId: data.externalId,
      metadata: data.metadata,
      lastModifiedAt: data.lastModifiedAt,
      createdAt: data.createdAt,
    );
  }

  HealthSample toEntity() {
    return HealthSample(
      id: id,
      type: type,
      startAt: startAt,
      endAt: endAt,
      value: value,
      unit: unit,
      source: source,
      externalId: externalId,
      metadata: metadata,
      lastModifiedAt: lastModifiedAt,
      createdAt: createdAt,
    );
  }

  HealthSamplesCompanion toCompanion() {
    return HealthSamplesCompanion(
      id: id == 0 ? const Value.absent() : Value(id),
      type: Value(type),
      startAt: Value(startAt),
      endAt: Value(endAt),
      value: Value(value),
      unit: Value(unit),
      source: Value(source),
      externalId: Value(externalId),
      metadata: Value(metadata),
      lastModifiedAt: Value(lastModifiedAt),
      createdAt: Value(createdAt),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'startAt': startAt.toIso8601String(),
      'endAt': endAt?.toIso8601String(),
      'value': value,
      'unit': unit,
      'source': source.name,
      'externalId': externalId,
      'metadata': metadata,
      'lastModifiedAt': lastModifiedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
