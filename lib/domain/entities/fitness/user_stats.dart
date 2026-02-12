class UserStats {
  const UserStats({
    required this.id,
    required this.date,
    required this.totalWorkouts,
    required this.totalVolume,
    required this.totalDuration,
    required this.streakDays,
    required this.medicationCompliance,
  });
  final int id;
  final DateTime date;
  final int totalWorkouts;
  final double totalVolume;
  final int totalDuration;
  final int streakDays;
  final double medicationCompliance;

  UserStats copyWith({
    int? id,
    DateTime? date,
    int? totalWorkouts,
    double? totalVolume,
    int? totalDuration,
    int? streakDays,
    double? medicationCompliance,
  }) {
    return UserStats(
      id: id ?? this.id,
      date: date ?? this.date,
      totalWorkouts: totalWorkouts ?? this.totalWorkouts,
      totalVolume: totalVolume ?? this.totalVolume,
      totalDuration: totalDuration ?? this.totalDuration,
      streakDays: streakDays ?? this.streakDays,
      medicationCompliance: medicationCompliance ?? this.medicationCompliance,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserStats &&
        other.id == id &&
        other.date == date &&
        other.totalWorkouts == totalWorkouts &&
        other.totalVolume == totalVolume &&
        other.totalDuration == totalDuration &&
        other.streakDays == streakDays &&
        other.medicationCompliance == medicationCompliance;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        date.hashCode ^
        totalWorkouts.hashCode ^
        totalVolume.hashCode ^
        totalDuration.hashCode ^
        streakDays.hashCode ^
        medicationCompliance.hashCode;
  }

  @override
  String toString() {
    return 'UserStats(id: $id, date: $date, totalWorkouts: $totalWorkouts, totalVolume: $totalVolume, totalDuration: $totalDuration, streakDays: $streakDays, medicationCompliance: $medicationCompliance)';
  }
}
