import 'package:drift/drift.dart';

import '../../../domain/entities/fitness/workout_set.dart';
import '../../local/database.dart';

/// WorkoutSet Model.
class WorkoutSetModel extends WorkoutSet {
  const WorkoutSetModel({
    required super.id,
    required super.sessionId,
    required super.exerciseId,
    required super.setNumber,
    required super.reps,
    required super.weight,
    required super.isWarmup,
    required super.isPR,
    required super.completedAt,
  });

  factory WorkoutSetModel.fromJson(Map<String, dynamic> json) {
    return WorkoutSetModel(
      id: json['id'] as int? ?? 0,
      sessionId: json['sessionId'] as int,
      exerciseId: json['exerciseId'] as int,
      setNumber: json['setNumber'] as int,
      reps: json['reps'] as int,
      weight: (json['weight'] as num).toDouble(),
      isWarmup: json['isWarmup'] as bool,
      isPR: json['isPR'] as bool,
      completedAt: DateTime.parse(json['completedAt'] as String),
    );
  }

  factory WorkoutSetModel.fromEntity(WorkoutSet entity) {
    return WorkoutSetModel(
      id: entity.id,
      sessionId: entity.sessionId,
      exerciseId: entity.exerciseId,
      setNumber: entity.setNumber,
      reps: entity.reps,
      weight: entity.weight,
      isWarmup: entity.isWarmup,
      isPR: entity.isPR,
      completedAt: entity.completedAt,
    );
  }

  factory WorkoutSetModel.fromDrift(WorkoutSetData data) {
    return WorkoutSetModel(
      id: data.id,
      sessionId: data.sessionId,
      exerciseId: data.exerciseId,
      setNumber: data.setNumber,
      reps: data.reps,
      weight: data.weight,
      isWarmup: data.isWarmup,
      isPR: data.isPR,
      completedAt: data.completedAt,
    );
  }

  WorkoutSet toEntity() {
    return WorkoutSet(
      id: id,
      sessionId: sessionId,
      exerciseId: exerciseId,
      setNumber: setNumber,
      reps: reps,
      weight: weight,
      isWarmup: isWarmup,
      isPR: isPR,
      completedAt: completedAt,
    );
  }

  WorkoutSetsCompanion toCompanion() {
    return WorkoutSetsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      exerciseId: Value(exerciseId),
      setNumber: Value(setNumber),
      reps: Value(reps),
      weight: Value(weight),
      isWarmup: Value(isWarmup),
      isPR: Value(isPR),
      completedAt: Value(completedAt),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'exerciseId': exerciseId,
      'setNumber': setNumber,
      'reps': reps,
      'weight': weight,
      'isWarmup': isWarmup,
      'isPR': isPR,
      'completedAt': completedAt.toIso8601String(),
    };
  }
}
