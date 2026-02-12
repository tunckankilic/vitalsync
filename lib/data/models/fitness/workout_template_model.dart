import 'package:drift/drift.dart';

import '../../../domain/entities/fitness/template_exercise.dart';
import '../../../domain/entities/fitness/workout_template.dart';
import '../../local/database.dart';
import 'template_exercise_model.dart';

/// WorkoutTemplate Model.
class WorkoutTemplateModel extends WorkoutTemplate {
  const WorkoutTemplateModel({
    required super.id,
    required super.name,
    required super.color,
    required super.estimatedDuration,
    required super.isDefault,
    required super.createdAt,
    required super.updatedAt,
    super.description,
    super.exercises,
  });
  factory WorkoutTemplateModel.fromJson(Map<String, dynamic> json) {
    return WorkoutTemplateModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String,
      description: json['description'] as String?,
      color: json['color'] as int,
      estimatedDuration: json['estimatedDuration'] as int,
      isDefault: json['isDefault'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      exercises: json['exercises'] != null
          ? (json['exercises'] as List)
                .map((e) => TemplateExerciseModel.fromJson(e))
                .toList()
          : [],
    );
  }

  factory WorkoutTemplateModel.fromEntity(WorkoutTemplate entity) {
    return WorkoutTemplateModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      color: entity.color,
      estimatedDuration: entity.estimatedDuration,
      isDefault: entity.isDefault,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      exercises: entity.exercises,
    );
  }

  factory WorkoutTemplateModel.fromDrift(
    WorkoutTemplateData data, {
    List<TemplateExercise>? exercises,
  }) {
    return WorkoutTemplateModel(
      id: data.id,
      name: data.name,
      description: data.description,
      color: data.color,
      estimatedDuration: data.estimatedDuration,
      isDefault: data.isDefault,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
      exercises: exercises ?? [],
    );
  }

  WorkoutTemplate toEntity() {
    return WorkoutTemplate(
      id: id,
      name: name,
      description: description,
      color: color,
      estimatedDuration: estimatedDuration,
      isDefault: isDefault,
      createdAt: createdAt,
      updatedAt: updatedAt,
      exercises: exercises,
    );
  }

  WorkoutTemplatesCompanion toCompanion() {
    return WorkoutTemplatesCompanion(
      id: Value(id),
      name: Value(name),
      description: Value(description),
      color: Value(color),
      estimatedDuration: Value(estimatedDuration),
      isDefault: Value(isDefault),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'estimatedDuration': estimatedDuration,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'exercises': exercises.map((e) {
        if (e is TemplateExerciseModel) {
          return e.toJson();
        } else {
          // Fallback if it's a plain entity
          return TemplateExerciseModel.fromEntity(e).toJson();
        }
      }).toList(),
    };
  }
}
