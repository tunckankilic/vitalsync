import 'package:drift/drift.dart';

import '../../../domain/entities/fitness/personal_record.dart';
import '../../local/database.dart';

/// PersonalRecord Model.
class PersonalRecordModel extends PersonalRecord {
  const PersonalRecordModel({
    required super.id,
    required super.exerciseId,
    required super.weight,
    required super.reps,
    required super.estimated1RM,
    required super.achievedAt,
  });

  factory PersonalRecordModel.fromJson(Map<String, dynamic> json) {
    return PersonalRecordModel(
      id: json['id'] as int? ?? 0,
      exerciseId: json['exerciseId'] as int,
      weight: (json['weight'] as num).toDouble(),
      reps: json['reps'] as int,
      estimated1RM: (json['estimated1RM'] as num).toDouble(),
      achievedAt: DateTime.parse(json['achievedAt'] as String),
    );
  }

  factory PersonalRecordModel.fromEntity(PersonalRecord entity) {
    return PersonalRecordModel(
      id: entity.id,
      exerciseId: entity.exerciseId,
      weight: entity.weight,
      reps: entity.reps,
      estimated1RM: entity.estimated1RM,
      achievedAt: entity.achievedAt,
    );
  }

  factory PersonalRecordModel.fromDrift(PersonalRecordData data) {
    return PersonalRecordModel(
      id: data.id,
      exerciseId: data.exerciseId,
      weight: data.weight,
      reps: data.reps,
      estimated1RM: data.estimated1RM,
      achievedAt: data.achievedAt,
    );
  }

  PersonalRecord toEntity() {
    return PersonalRecord(
      id: id,
      exerciseId: exerciseId,
      weight: weight,
      reps: reps,
      estimated1RM: estimated1RM,
      achievedAt: achievedAt,
    );
  }

  PersonalRecordsCompanion toCompanion() {
    return PersonalRecordsCompanion(
      id: Value(id),
      exerciseId: Value(exerciseId),
      weight: Value(weight),
      reps: Value(reps),
      estimated1RM: Value(estimated1RM),
      achievedAt: Value(achievedAt),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exerciseId': exerciseId,
      'weight': weight,
      'reps': reps,
      'estimated1RM': estimated1RM,
      'achievedAt': achievedAt.toIso8601String(),
    };
  }
}
