import 'package:drift/drift.dart';

import '../../../domain/entities/fitness/user_stats.dart';
import '../../local/database.dart';

/// UserStats Model.
class UserStatsModel extends UserStats {
  const UserStatsModel({
    required super.id,
    required super.date,
    required super.totalWorkouts,
    required super.totalVolume,
    required super.totalDuration,
    required super.streakDays,
    required super.medicationCompliance,
  });
  factory UserStatsModel.fromJson(Map<String, dynamic> json) {
    return UserStatsModel(
      id: json['id'] as int? ?? 0,
      date: DateTime.parse(json['date'] as String),
      totalWorkouts: json['totalWorkouts'] as int,
      totalVolume: (json['totalVolume'] as num).toDouble(),
      totalDuration: json['totalDuration'] as int,
      streakDays: json['streakDays'] as int,
      medicationCompliance: (json['medicationCompliance'] as num).toDouble(),
    );
  }

  factory UserStatsModel.fromEntity(UserStats entity) {
    return UserStatsModel(
      id: entity.id,
      date: entity.date,
      totalWorkouts: entity.totalWorkouts,
      totalVolume: entity.totalVolume,
      totalDuration: entity.totalDuration,
      streakDays: entity.streakDays,
      medicationCompliance: entity.medicationCompliance,
    );
  }

  factory UserStatsModel.fromDrift(UserStatsData data) {
    return UserStatsModel(
      id: data.id,
      date: data.date,
      totalWorkouts: data.totalWorkouts,
      totalVolume: data.totalVolume,
      totalDuration: data.totalDuration,
      streakDays: data.streakDays,
      medicationCompliance: data.medicationCompliance,
    );
  }

  UserStats toEntity() {
    return UserStats(
      id: id,
      date: date,
      totalWorkouts: totalWorkouts,
      totalVolume: totalVolume,
      totalDuration: totalDuration,
      streakDays: streakDays,
      medicationCompliance: medicationCompliance,
    );
  }

  UserStatsCompanion toCompanion() {
    return UserStatsCompanion(
      id: Value(id),
      date: Value(date),
      totalWorkouts: Value(totalWorkouts),
      totalVolume: Value(totalVolume),
      totalDuration: Value(totalDuration),
      streakDays: Value(streakDays),
      medicationCompliance: Value(medicationCompliance),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'totalWorkouts': totalWorkouts,
      'totalVolume': totalVolume,
      'totalDuration': totalDuration,
      'streakDays': streakDays,
      'medicationCompliance': medicationCompliance,
    };
  }
}
