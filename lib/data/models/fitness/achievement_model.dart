import 'package:drift/drift.dart';

import '../../../core/enums/achievement_type.dart';
import '../../../domain/entities/fitness/achievement.dart';
import '../../local/database.dart';

/// Achievement Model.
class AchievementModel extends Achievement {
  const AchievementModel({
    required super.id,
    required super.type,
    required super.title,
    required super.description,
    required super.requirement,
    required super.iconName,
    super.unlockedAt,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      id: json['id'] as int? ?? 0,
      type: AchievementType.values.firstWhere((e) => e.name == json['type']),
      title: json['title'] as String,
      description: json['description'] as String,
      requirement: json['requirement'] as int,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
      iconName: json['iconName'] as String,
    );
  }

  factory AchievementModel.fromEntity(Achievement entity) {
    return AchievementModel(
      id: entity.id,
      type: entity.type,
      title: entity.title,
      description: entity.description,
      requirement: entity.requirement,
      unlockedAt: entity.unlockedAt,
      iconName: entity.iconName,
    );
  }

  factory AchievementModel.fromDrift(AchievementData data) {
    return AchievementModel(
      id: data.id,
      type: data.type,
      title: data.title,
      description: data.description,
      requirement: data.requirement,
      unlockedAt: data.unlockedAt,
      iconName: data.iconName,
    );
  }

  Achievement toEntity() {
    return Achievement(
      id: id,
      type: type,
      title: title,
      description: description,
      requirement: requirement,
      unlockedAt: unlockedAt,
      iconName: iconName,
    );
  }

  AchievementsCompanion toCompanion() {
    return AchievementsCompanion(
      id: Value(id),
      type: Value(type),
      title: Value(title),
      description: Value(description),
      requirement: Value(requirement),
      unlockedAt: Value(unlockedAt),
      iconName: Value(iconName),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'description': description,
      'requirement': requirement,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'iconName': iconName,
    };
  }
}
