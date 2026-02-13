import 'exercise.dart';

class TemplateExercise {
  const TemplateExercise({
    required this.id,
    required this.templateId,
    required this.exerciseId,
    required this.orderIndex,
    required this.defaultSets,
    required this.defaultReps,
    required this.restSeconds,
    this.defaultWeight,
    this.exercise,
  });
  final int id;
  final int templateId;
  final int exerciseId;
  final int orderIndex;
  final int defaultSets;
  final int defaultReps;
  final double? defaultWeight;
  final int restSeconds;
  // Optional full exercise details for UI
  final Exercise? exercise;

  TemplateExercise copyWith({
    int? id,
    int? templateId,
    int? exerciseId,
    int? orderIndex,
    int? defaultSets,
    int? defaultReps,
    double? defaultWeight,
    int? restSeconds,
    Exercise? exercise,
  }) {
    return TemplateExercise(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      exerciseId: exerciseId ?? this.exerciseId,
      orderIndex: orderIndex ?? this.orderIndex,
      defaultSets: defaultSets ?? this.defaultSets,
      defaultReps: defaultReps ?? this.defaultReps,
      defaultWeight: defaultWeight ?? this.defaultWeight,
      restSeconds: restSeconds ?? this.restSeconds,
      exercise: exercise ?? this.exercise,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TemplateExercise &&
        other.id == id &&
        other.templateId == templateId &&
        other.exerciseId == exerciseId &&
        other.orderIndex == orderIndex &&
        other.defaultSets == defaultSets &&
        other.defaultReps == defaultReps &&
        other.defaultWeight == defaultWeight &&
        other.restSeconds == restSeconds &&
        other.exercise == exercise;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        templateId.hashCode ^
        exerciseId.hashCode ^
        orderIndex.hashCode ^
        defaultSets.hashCode ^
        defaultReps.hashCode ^
        defaultWeight.hashCode ^
        restSeconds.hashCode ^
        exercise.hashCode;
  }

  @override
  String toString() {
    return 'TemplateExercise(id: $id, templateId: $templateId, exerciseId: $exerciseId, orderIndex: $orderIndex, defaultSets: $defaultSets, defaultReps: $defaultReps, defaultWeight: $defaultWeight, restSeconds: $restSeconds, exercise: $exercise)';
  }
}
