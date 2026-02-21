import 'package:drift/drift.dart';

import '../../../core/enums/sync_status.dart';
import '../../../core/enums/workout_rating.dart';
import '../../../domain/entities/fitness/workout_session.dart';
import '../../local/database.dart';

/// WorkoutSession Model.
class WorkoutSessionModel extends WorkoutSession {
  const WorkoutSessionModel({
    required super.id,
    required super.name,
    required super.startTime,
    required super.lastModifiedAt,
    required super.createdAt,
    super.templateId,
    super.endTime,
    super.totalVolume,
    super.notes,
    super.rating,
    super.syncStatus,
  });

  factory WorkoutSessionModel.fromJson(Map<String, dynamic> json) {
    return WorkoutSessionModel(
      id: json['id'] as int? ?? 0,
      templateId: json['templateId'] as int?,
      name: json['name'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      totalVolume: (json['totalVolume'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
      rating: json['rating'] != null
          ? WorkoutRating.values.firstWhere(
              (e) => e.name == json['rating'],
              orElse: () => WorkoutRating.okay,
            )
          : null,
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == json['syncStatus'],
        orElse: () => SyncStatus.synced,
      ),
      lastModifiedAt: DateTime.parse(json['lastModifiedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  factory WorkoutSessionModel.fromEntity(WorkoutSession entity) {
    return WorkoutSessionModel(
      id: entity.id,
      templateId: entity.templateId,
      name: entity.name,
      startTime: entity.startTime,
      endTime: entity.endTime,
      totalVolume: entity.totalVolume,
      notes: entity.notes,
      rating: entity.rating,
      syncStatus: entity.syncStatus,
      lastModifiedAt: entity.lastModifiedAt,
      createdAt: entity.createdAt,
    );
  }

  factory WorkoutSessionModel.fromDrift(WorkoutSessionData data) {
    return WorkoutSessionModel(
      id: data.id,
      templateId: data.templateId,
      name: data.name,
      startTime: data.startTime,
      endTime: data.endTime,
      totalVolume: data.totalVolume,
      notes: data.notes,
      rating: data.rating != null
          ? WorkoutRating.fromValue(data.rating as int)
          : null,
      syncStatus: data.syncStatus,
      lastModifiedAt: data.lastModifiedAt,
      createdAt: data.createdAt,
    );
  }

  WorkoutSession toEntity() {
    return WorkoutSession(
      id: id,
      templateId: templateId,
      name: name,
      startTime: startTime,
      endTime: endTime,
      totalVolume: totalVolume,
      notes: notes,
      rating: rating,
      syncStatus: syncStatus,
      lastModifiedAt: lastModifiedAt,
      createdAt: createdAt,
    );
  }

  WorkoutSessionsCompanion toCompanion() {
    return WorkoutSessionsCompanion(
      id: Value(id),
      templateId: Value(templateId),
      name: Value(name),
      startTime: Value(startTime),
      endTime: Value(endTime),
      totalVolume: Value(totalVolume),
      notes: Value(notes),
      rating: Value(rating ?? WorkoutRating.okay),
      syncStatus: Value(syncStatus),
      lastModifiedAt: Value(lastModifiedAt),
      createdAt: Value(createdAt),
    );
  }
}
