import 'package:drift/drift.dart';

import '../../../core/enums/equipment.dart';
import '../../../core/enums/exercise_category.dart';
import '../../../domain/entities/fitness/exercise.dart';
import '../../local/database.dart';

/// Exercise Model.
class ExerciseModel extends Exercise {
  const ExerciseModel({
    required super.id,
    required super.name,
    required super.category,
    required super.muscleGroup,
    required super.equipment,
    required super.isCustom,
    required super.createdAt,
    super.instructions,
  });
  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String,
      category: ExerciseCategory.values.firstWhere(
        (e) => e.name == json['category'],
      ),
      muscleGroup: json['muscleGroup'] as String,
      equipment: Equipment.values.firstWhere(
        (e) => e.name == json['equipment'],
      ),
      instructions: json['instructions'] as String?,
      isCustom: json['isCustom'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  factory ExerciseModel.fromEntity(Exercise entity) {
    return ExerciseModel(
      id: entity.id,
      name: entity.name,
      category: entity.category,
      muscleGroup: entity.muscleGroup,
      equipment: entity.equipment,
      instructions: entity.instructions,
      isCustom: entity.isCustom,
      createdAt: entity.createdAt,
    );
  }

  factory ExerciseModel.fromDrift(ExerciseData data) {
    return ExerciseModel(
      id: data.id,
      name: data.name,
      category: data.category,
      muscleGroup: data.muscleGroup,
      equipment: data.equipment,
      instructions: data.instructions,
      isCustom: data.isCustom,
      createdAt: data.createdAt,
    );
  }

  Exercise toEntity() {
    return Exercise(
      id: id,
      name: name,
      category: category,
      muscleGroup: muscleGroup,
      equipment: equipment,
      instructions: instructions,
      isCustom: isCustom,
      createdAt: createdAt,
    );
  }

  ExercisesCompanion toCompanion() {
    return ExercisesCompanion(
      id: Value(id),
      name: Value(name),
      category: Value(category),
      muscleGroup: Value(muscleGroup),
      equipment: Value(equipment),
      instructions: Value(instructions),
      isCustom: Value(isCustom),
      createdAt: Value(createdAt),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'muscleGroup': muscleGroup,
      'equipment': equipment.name,
      'instructions': instructions,
      'isCustom': isCustom,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
