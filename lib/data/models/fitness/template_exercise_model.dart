import 'package:drift/drift.dart';

import '../../../domain/entities/fitness/template_exercise.dart';
import '../../local/database.dart';
import 'exercise_model.dart';

/// TemplateExercise Model.
class TemplateExerciseModel extends TemplateExercise {
  const TemplateExerciseModel({
    required super.id,
    required super.templateId,
    required super.exerciseId,
    required super.orderIndex,
    required super.defaultSets,
    required super.defaultReps,
    required super.restSeconds,
    super.defaultWeight,
    super.exercise,
  });

  factory TemplateExerciseModel.fromJson(Map<String, dynamic> json) {
    return TemplateExerciseModel(
      id: json['id'] as int? ?? 0,
      templateId: json['templateId'] as int,
      exerciseId: json['exerciseId'] as int,
      orderIndex: json['orderIndex'] as int,
      defaultSets: json['defaultSets'] as int,
      defaultReps: json['defaultReps'] as int,
      defaultWeight: (json['defaultWeight'] as num?)?.toDouble(),
      restSeconds: json['restSeconds'] as int,
      // Exercise is typically not included in flat JSON export, but if it is, we can parse it
      exercise: json['exercise'] != null
          ? ExerciseModel.fromJson(json['exercise'])
          : null,
    );
  }

  factory TemplateExerciseModel.fromEntity(TemplateExercise entity) {
    return TemplateExerciseModel(
      id: entity.id,
      templateId: entity.templateId,
      exerciseId: entity.exerciseId,
      orderIndex: entity.orderIndex,
      defaultSets: entity.defaultSets,
      defaultReps: entity.defaultReps,
      defaultWeight: entity.defaultWeight,
      restSeconds: entity.restSeconds,
      exercise: entity.exercise,
    );
  }

  factory TemplateExerciseModel.fromDrift(
    TemplateExerciseData data, {
    ExerciseModel? exercise,
  }) {
    return TemplateExerciseModel(
      id: data.id,
      templateId: data.templateId,
      exerciseId: data.exerciseId,
      orderIndex: data.orderIndex,
      defaultSets: data.defaultSets,
      defaultReps: data.defaultReps,
      defaultWeight: data.defaultWeight,
      restSeconds: data.restSeconds,
      exercise: exercise,
    );
  }

  TemplateExercise toEntity() {
    return TemplateExercise(
      id: id,
      templateId: templateId,
      exerciseId: exerciseId,
      orderIndex: orderIndex,
      defaultSets: defaultSets,
      defaultReps: defaultReps,
      defaultWeight: defaultWeight,
      restSeconds: restSeconds,
      exercise: exercise,
    );
  }

  TemplateExercisesCompanion toCompanion() {
    return TemplateExercisesCompanion(
      id: Value(id),
      templateId: Value(templateId),
      exerciseId: Value(exerciseId),
      orderIndex: Value(orderIndex),
      defaultSets: Value(defaultSets),
      defaultReps: Value(defaultReps),
      defaultWeight: Value(defaultWeight),
      restSeconds: Value(restSeconds),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'templateId': templateId,
      'exerciseId': exerciseId,
      'orderIndex': orderIndex,
      'defaultSets': defaultSets,
      'defaultReps': defaultReps,
      'defaultWeight': defaultWeight,
      'restSeconds': restSeconds,
    };
  }
}
