import '../../../domain/entities/insights/weekly_report.dart';

/// WeeklyReport Model.
class WeeklyReportModel extends WeeklyReport {
  const WeeklyReportModel({
    required super.startDate,
    required super.endDate,
    required super.generatedAt,
    // Health Summary
    required super.medicationCompliance,
    required super.complianceTrendVsPrevious,
    required super.missedMedicationsCount,
    super.mostProblematicTimeSlot,
    required super.symptomsLoggedCount,
    super.mostFrequentSymptom,
    // Fitness Summary
    required super.workoutCount,
    required super.totalVolume,
    required super.volumeTrendVsPrevious,
    required super.totalWorkoutDuration,
    required super.newPRs,
    required super.currentStreak,
    // Cross-Module Highlights
    super.bestDay,
    required super.healthScore,
    required super.topInsights,
    // Next Week Suggestions
    required super.suggestions,
  });

  factory WeeklyReportModel.fromEntity(WeeklyReport entity) {
    return WeeklyReportModel(
      startDate: entity.startDate,
      endDate: entity.endDate,
      generatedAt: entity.generatedAt,
      medicationCompliance: entity.medicationCompliance,
      complianceTrendVsPrevious: entity.complianceTrendVsPrevious,
      missedMedicationsCount: entity.missedMedicationsCount,
      mostProblematicTimeSlot: entity.mostProblematicTimeSlot,
      symptomsLoggedCount: entity.symptomsLoggedCount,
      mostFrequentSymptom: entity.mostFrequentSymptom,
      workoutCount: entity.workoutCount,
      totalVolume: entity.totalVolume,
      volumeTrendVsPrevious: entity.volumeTrendVsPrevious,
      totalWorkoutDuration: entity.totalWorkoutDuration,
      newPRs: entity.newPRs,
      currentStreak: entity.currentStreak,
      bestDay: entity.bestDay,
      healthScore: entity.healthScore,
      topInsights: entity.topInsights,
      suggestions: entity.suggestions,
    );
  }

  factory WeeklyReportModel.fromJson(Map<String, dynamic> json) {
    return WeeklyReport.fromJson(json) as WeeklyReportModel;
  }

  @override
  Map<String, dynamic> toJson() {
    // Delegate to parent class which has comprehensive JSON serialization
    return super.toJson();
  }
}
