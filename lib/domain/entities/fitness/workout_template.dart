import 'template_exercise.dart';

class WorkoutTemplate {
  const WorkoutTemplate({
    required this.id,
    required this.name,
    required this.color,
    required this.estimatedDuration,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.exercises = const [],
  });
  final int id;
  final String name;
  final String? description;
  final int color;
  final int estimatedDuration;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TemplateExercise> exercises;

  WorkoutTemplate copyWith({
    int? id,
    String? name,
    String? description,
    int? color,
    int? estimatedDuration,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TemplateExercise>? exercises,
  }) {
    return WorkoutTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      exercises: exercises ?? this.exercises,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WorkoutTemplate &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.color == color &&
        other.estimatedDuration == estimatedDuration &&
        other.isDefault == isDefault &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.exercises.length == exercises.length &&
        other.exercises.asMap().entries.every(
          (e) => e.value == exercises[e.key],
        );
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        color.hashCode ^
        estimatedDuration.hashCode ^
        isDefault.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        exercises.hashCode;
  }

  @override
  String toString() {
    return 'WorkoutTemplate(id: $id, name: $name, description: $description, color: $color, estimatedDuration: $estimatedDuration, isDefault: $isDefault, createdAt: $createdAt, updatedAt: $updatedAt, exercises: $exercises)';
  }
}
