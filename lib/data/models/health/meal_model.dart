import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/enums/sync_status.dart';
import '../../../domain/entities/health/meal.dart';
import '../../local/database.dart';

/// Meal Model.
class MealModel extends Meal {
  const MealModel({
    required super.id,
    required super.name,
    required super.eatenAt,
    required super.tags,
    required super.lastModifiedAt,
    required super.createdAt,
    super.notes,
    super.syncStatus,
  });

  factory MealModel.fromJson(Map<String, dynamic> json) {
    return MealModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String,
      eatenAt: DateTime.parse(json['eatenAt'] as String),
      notes: json['notes'] as String?,
      tags: (json['tags'] as List).cast<String>(),
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == json['syncStatus'],
        orElse: () => SyncStatus.synced,
      ),
      lastModifiedAt: DateTime.parse(json['lastModifiedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  factory MealModel.fromEntity(Meal entity) {
    return MealModel(
      id: entity.id,
      name: entity.name,
      eatenAt: entity.eatenAt,
      notes: entity.notes,
      tags: entity.tags,
      syncStatus: entity.syncStatus,
      lastModifiedAt: entity.lastModifiedAt,
      createdAt: entity.createdAt,
    );
  }

  factory MealModel.fromDrift(MealData data) {
    return MealModel(
      id: data.id,
      name: data.name,
      eatenAt: data.eatenAt,
      notes: data.notes,
      tags: (jsonDecode(data.tags) as List).cast<String>(),
      syncStatus: data.syncStatus,
      lastModifiedAt: data.lastModifiedAt,
      createdAt: data.createdAt,
    );
  }

  Meal toEntity() {
    return Meal(
      id: id,
      name: name,
      eatenAt: eatenAt,
      notes: notes,
      tags: tags,
      syncStatus: syncStatus,
      lastModifiedAt: lastModifiedAt,
      createdAt: createdAt,
    );
  }

  MealsCompanion toCompanion() {
    return MealsCompanion(
      id: id == 0 ? const Value.absent() : Value(id),
      name: Value(name),
      eatenAt: Value(eatenAt),
      notes: Value(notes),
      tags: Value(jsonEncode(tags)),
      syncStatus: Value(syncStatus),
      lastModifiedAt: Value(lastModifiedAt),
      createdAt: Value(createdAt),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'eatenAt': eatenAt.toIso8601String(),
      'notes': notes,
      'tags': tags,
      'syncStatus': syncStatus.name,
      'lastModifiedAt': lastModifiedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
