class PersonalRecord {
  const PersonalRecord({
    required this.id,
    required this.exerciseId,
    required this.weight,
    required this.reps,
    required this.estimated1RM,
    required this.achievedAt,
  });
  final int id;
  final int exerciseId;
  final double weight;
  final int reps;
  final double estimated1RM;
  final DateTime achievedAt;

  PersonalRecord copyWith({
    int? id,
    int? exerciseId,
    double? weight,
    int? reps,
    double? estimated1RM,
    DateTime? achievedAt,
  }) {
    return PersonalRecord(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      estimated1RM: estimated1RM ?? this.estimated1RM,
      achievedAt: achievedAt ?? this.achievedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PersonalRecord &&
        other.id == id &&
        other.exerciseId == exerciseId &&
        other.weight == weight &&
        other.reps == reps &&
        other.estimated1RM == estimated1RM &&
        other.achievedAt == achievedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        exerciseId.hashCode ^
        weight.hashCode ^
        reps.hashCode ^
        estimated1RM.hashCode ^
        achievedAt.hashCode;
  }

  @override
  String toString() {
    return 'PersonalRecord(id: $id, exerciseId: $exerciseId, weight: $weight, reps: $reps, estimated1RM: $estimated1RM, achievedAt: $achievedAt)';
  }
}
