import 'package:drift/drift.dart';

import '../../../core/enums/glucose_source.dart';
import '../../../core/enums/meal_context.dart';
import '../../../core/enums/sync_status.dart';
import '../../../domain/entities/health/glucose_reading.dart';
import '../../local/database.dart';

/// Glucose Reading Model.
class GlucoseReadingModel extends GlucoseReading {
  const GlucoseReadingModel({
    required super.id,
    required super.valueMgDl,
    required super.measuredAt,
    required super.source,
    required super.lastModifiedAt,
    required super.createdAt,
    super.externalId,
    super.mealContext,
    super.notes,
    super.syncStatus,
  });

  factory GlucoseReadingModel.fromJson(Map<String, dynamic> json) {
    return GlucoseReadingModel(
      id: json['id'] as int? ?? 0,
      valueMgDl: (json['valueMgDl'] as num).toDouble(),
      measuredAt: DateTime.parse(json['measuredAt'] as String),
      source: GlucoseSource.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => GlucoseSource.manual,
      ),
      externalId: json['externalId'] as String?,
      mealContext: json['mealContext'] != null
          ? MealContext.values.firstWhere(
              (e) => e.name == json['mealContext'],
              orElse: () => MealContext.other,
            )
          : null,
      notes: json['notes'] as String?,
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == json['syncStatus'],
        orElse: () => SyncStatus.synced,
      ),
      lastModifiedAt: DateTime.parse(json['lastModifiedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  factory GlucoseReadingModel.fromEntity(GlucoseReading entity) {
    return GlucoseReadingModel(
      id: entity.id,
      valueMgDl: entity.valueMgDl,
      measuredAt: entity.measuredAt,
      source: entity.source,
      externalId: entity.externalId,
      mealContext: entity.mealContext,
      notes: entity.notes,
      syncStatus: entity.syncStatus,
      lastModifiedAt: entity.lastModifiedAt,
      createdAt: entity.createdAt,
    );
  }

  factory GlucoseReadingModel.fromDrift(GlucoseReadingData data) {
    return GlucoseReadingModel(
      id: data.id,
      valueMgDl: data.valueMgDl,
      measuredAt: data.measuredAt,
      source: data.source,
      externalId: data.externalId,
      mealContext: data.mealContext,
      notes: data.notes,
      syncStatus: data.syncStatus,
      lastModifiedAt: data.lastModifiedAt,
      createdAt: data.createdAt,
    );
  }

  GlucoseReading toEntity() {
    return GlucoseReading(
      id: id,
      valueMgDl: valueMgDl,
      measuredAt: measuredAt,
      source: source,
      externalId: externalId,
      mealContext: mealContext,
      notes: notes,
      syncStatus: syncStatus,
      lastModifiedAt: lastModifiedAt,
      createdAt: createdAt,
    );
  }

  GlucoseReadingsCompanion toCompanion() {
    return GlucoseReadingsCompanion(
      id: id == 0 ? const Value.absent() : Value(id),
      valueMgDl: Value(valueMgDl),
      measuredAt: Value(measuredAt),
      source: Value(source),
      externalId: Value(externalId),
      mealContext: Value(mealContext),
      notes: Value(notes),
      syncStatus: Value(syncStatus),
      lastModifiedAt: Value(lastModifiedAt),
      createdAt: Value(createdAt),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'valueMgDl': valueMgDl,
      'measuredAt': measuredAt.toIso8601String(),
      'source': source.name,
      'externalId': externalId,
      'mealContext': mealContext?.name,
      'notes': notes,
      'syncStatus': syncStatus.name,
      'lastModifiedAt': lastModifiedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
