import '../../../domain/entities/insights/weekly_report.dart';
import 'insight_model.dart';

/// WeeklyReport Model.
class WeeklyReportModel extends WeeklyReport {
  const WeeklyReportModel({
    required super.startDate,
    required super.endDate,
    required super.medicationCompliance,
    required super.workoutCount,
    required super.totalVolume,
    required super.topInsights,
    required super.symptomSummary,
    required super.generatedAt,
  });

  factory WeeklyReportModel.fromEntity(WeeklyReport entity) {
    return WeeklyReportModel(
      startDate: entity.startDate,
      endDate: entity.endDate,
      medicationCompliance: entity.medicationCompliance,
      workoutCount: entity.workoutCount,
      totalVolume: entity.totalVolume,
      topInsights: entity.topInsights,
      symptomSummary: entity.symptomSummary,
      generatedAt: entity.generatedAt,
    );
  }

  factory WeeklyReportModel.fromJson(Map<String, dynamic> json) {
    return WeeklyReportModel(
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      medicationCompliance: (json['medicationCompliance'] as num).toDouble(),
      workoutCount: json['workoutCount'] as int,
      totalVolume: (json['totalVolume'] as num).toDouble(),
      topInsights: (json['topInsights'] as List)
          .map((e) => InsightModel.fromJson(e))
          .toList(),
      symptomSummary: json['symptomSummary'] as String,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'medicationCompliance': medicationCompliance,
      'workoutCount': workoutCount,
      'totalVolume': totalVolume,
      'topInsights': topInsights.map((e) {
        if (e is InsightModel) {
          return e.toJson();
        } else {
          return InsightModel.fromEntity(e).toJson();
        }
      }).toList(),
      'symptomSummary': symptomSummary,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }
}
