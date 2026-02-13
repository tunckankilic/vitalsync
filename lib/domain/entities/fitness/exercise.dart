import '../../../core/enums/equipment.dart';
import '../../../core/enums/exercise_category.dart';

class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.muscleGroup,
    required this.equipment,
    required this.isCustom,
    required this.createdAt,
    this.instructions,
  });

  final int id;
  final String name;
  final ExerciseCategory category;
  final String muscleGroup;
  final Equipment equipment;
  final String? instructions;
  final bool isCustom;
  final DateTime createdAt;

  Exercise copyWith({
    int? id,
    String? name,
    ExerciseCategory? category,
    String? muscleGroup,
    Equipment? equipment,
    String? instructions,
    bool? isCustom,
    DateTime? createdAt,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      equipment: equipment ?? this.equipment,
      instructions: instructions ?? this.instructions,
      isCustom: isCustom ?? this.isCustom,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Exercise &&
        other.id == id &&
        other.name == name &&
        other.category == category &&
        other.muscleGroup == muscleGroup &&
        other.equipment == equipment &&
        other.instructions == instructions &&
        other.isCustom == isCustom &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        category.hashCode ^
        muscleGroup.hashCode ^
        equipment.hashCode ^
        instructions.hashCode ^
        isCustom.hashCode ^
        createdAt.hashCode;
  }

  @override
  String toString() {
    return 'Exercise(id: $id, name: $name, category: $category, muscleGroup: $muscleGroup, equipment: $equipment, instructions: $instructions, isCustom: $isCustom, createdAt: $createdAt)';
  }
}
