import 'insight.dart';

class WeeklyReport {
  const WeeklyReport({
    required this.startDate,
    required this.endDate,
    required this.medicationCompliance,
    required this.workoutCount,
    required this.totalVolume,
    required this.topInsights,
    required this.symptomSummary,
    required this.generatedAt,
  });
  final DateTime startDate;
  final DateTime endDate;
  final double medicationCompliance;
  final int workoutCount;
  final double totalVolume;
  final List<Insight> topInsights;
  final String symptomSummary;
  final DateTime generatedAt;

  WeeklyReport copyWith({
    DateTime? startDate,
    DateTime? endDate,
    double? medicationCompliance,
    int? workoutCount,
    double? totalVolume,
    List<Insight>? topInsights,
    String? symptomSummary,
    DateTime? generatedAt,
  }) {
    return WeeklyReport(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      medicationCompliance: medicationCompliance ?? this.medicationCompliance,
      workoutCount: workoutCount ?? this.workoutCount,
      totalVolume: totalVolume ?? this.totalVolume,
      topInsights: topInsights ?? this.topInsights,
      symptomSummary: symptomSummary ?? this.symptomSummary,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WeeklyReport &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.medicationCompliance == medicationCompliance &&
        other.workoutCount == workoutCount &&
        other.totalVolume == totalVolume &&
        other.topInsights.length == topInsights.length &&
        other.topInsights.asMap().entries.every(
          (e) => e.value == topInsights[e.key],
        ) &&
        other.symptomSummary == symptomSummary &&
        other.generatedAt == generatedAt;
  }

  @override
  int get hashCode {
    return startDate.hashCode ^
        endDate.hashCode ^
        medicationCompliance.hashCode ^
        workoutCount.hashCode ^
        totalVolume.hashCode ^
        topInsights.hashCode ^
        symptomSummary.hashCode ^
        generatedAt.hashCode;
  }

  @override
  String toString() {
    return 'WeeklyReport(startDate: $startDate, endDate: $endDate, medicationCompliance: $medicationCompliance, workoutCount: $workoutCount, totalVolume: $totalVolume, topInsights: $topInsights, symptomSummary: $symptomSummary, generatedAt: $generatedAt)';
  }
}
