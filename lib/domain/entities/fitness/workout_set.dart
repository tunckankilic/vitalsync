class WorkoutSet {
  const WorkoutSet({
    required this.id,
    required this.sessionId,
    required this.exerciseId,
    required this.setNumber,
    required this.reps,
    required this.weight,
    required this.isWarmup,
    required this.isPR,
    required this.completedAt,
  });
  final int id;
  final int sessionId;
  final int exerciseId;
  final int setNumber;
  final int reps;
  final double weight;
  final bool isWarmup;
  final bool isPR;
  final DateTime completedAt;

  WorkoutSet copyWith({
    int? id,
    int? sessionId,
    int? exerciseId,
    int? setNumber,
    int? reps,
    double? weight,
    bool? isWarmup,
    bool? isPR,
    DateTime? completedAt,
  }) {
    return WorkoutSet(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      exerciseId: exerciseId ?? this.exerciseId,
      setNumber: setNumber ?? this.setNumber,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      isWarmup: isWarmup ?? this.isWarmup,
      isPR: isPR ?? this.isPR,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WorkoutSet &&
        other.id == id &&
        other.sessionId == sessionId &&
        other.exerciseId == exerciseId &&
        other.setNumber == setNumber &&
        other.reps == reps &&
        other.weight == weight &&
        other.isWarmup == isWarmup &&
        other.isPR == isPR &&
        other.completedAt == completedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        sessionId.hashCode ^
        exerciseId.hashCode ^
        setNumber.hashCode ^
        reps.hashCode ^
        weight.hashCode ^
        isWarmup.hashCode ^
        isPR.hashCode ^
        completedAt.hashCode;
  }

  @override
  String toString() {
    return 'WorkoutSet(id: $id, sessionId: $sessionId, exerciseId: $exerciseId, setNumber: $setNumber, reps: $reps, weight: $weight, isWarmup: $isWarmup, isPR: $isPR, completedAt: $completedAt)';
  }
}
