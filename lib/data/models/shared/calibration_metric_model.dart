import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/enums/sync_status.dart';
import '../../../domain/entities/shared/calibration_metric.dart';
import '../../local/database.dart';

/// Calibration Metric Model.
///
/// **Counts only, no interpretation.** This model moves tallies between
/// layers; it derives nothing from them.
class CalibrationMetricModel extends CalibrationMetric {
  const CalibrationMetricModel({
    required super.id,
    required super.weekStart,
    required super.mealsLogged,
    required super.glucoseReadings,
    required super.manualReadings,
    required super.coveredMeals,
    required super.uncoveredReasons,
    required super.appVersion,
    required super.lastModifiedAt,
    required super.createdAt,
    super.syncStatus,
  });

  factory CalibrationMetricModel.fromJson(Map<String, dynamic> json) {
    return CalibrationMetricModel(
      id: json['id'] as int? ?? 0,
      weekStart: DateTime.parse(json['weekStart'] as String),
      mealsLogged: json['mealsLogged'] as int,
      glucoseReadings: json['glucoseReadings'] as int,
      manualReadings: json['manualReadings'] as int,
      coveredMeals: json['coveredMeals'] as int,
      uncoveredReasons: (json['uncoveredReasons'] as Map).map(
        (key, value) => MapEntry(key as String, value as int),
      ),
      appVersion: json['appVersion'] as String,
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == json['syncStatus'],
        orElse: () => SyncStatus.synced,
      ),
      lastModifiedAt: DateTime.parse(json['lastModifiedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  factory CalibrationMetricModel.fromEntity(CalibrationMetric entity) {
    return CalibrationMetricModel(
      id: entity.id,
      weekStart: entity.weekStart,
      mealsLogged: entity.mealsLogged,
      glucoseReadings: entity.glucoseReadings,
      manualReadings: entity.manualReadings,
      coveredMeals: entity.coveredMeals,
      uncoveredReasons: entity.uncoveredReasons,
      appVersion: entity.appVersion,
      syncStatus: entity.syncStatus,
      lastModifiedAt: entity.lastModifiedAt,
      createdAt: entity.createdAt,
    );
  }

  factory CalibrationMetricModel.fromDrift(CalibrationMetricData data) {
    return CalibrationMetricModel(
      id: data.id,
      weekStart: data.weekStart,
      mealsLogged: data.mealsLogged,
      glucoseReadings: data.glucoseReadings,
      manualReadings: data.manualReadings,
      coveredMeals: data.coveredMeals,
      uncoveredReasons: (jsonDecode(data.uncoveredReasons) as Map).map(
        (key, value) => MapEntry(key as String, value as int),
      ),
      appVersion: data.appVersion,
      syncStatus: data.syncStatus,
      lastModifiedAt: data.lastModifiedAt,
      createdAt: data.createdAt,
    );
  }

  CalibrationMetric toEntity() {
    return CalibrationMetric(
      id: id,
      weekStart: weekStart,
      mealsLogged: mealsLogged,
      glucoseReadings: glucoseReadings,
      manualReadings: manualReadings,
      coveredMeals: coveredMeals,
      uncoveredReasons: uncoveredReasons,
      appVersion: appVersion,
      syncStatus: syncStatus,
      lastModifiedAt: lastModifiedAt,
      createdAt: createdAt,
    );
  }

  CalibrationMetricsCompanion toCompanion() {
    return CalibrationMetricsCompanion(
      id: id == 0 ? const Value.absent() : Value(id),
      weekStart: Value(weekStart),
      mealsLogged: Value(mealsLogged),
      glucoseReadings: Value(glucoseReadings),
      manualReadings: Value(manualReadings),
      coveredMeals: Value(coveredMeals),
      uncoveredReasons: Value(jsonEncode(uncoveredReasons)),
      appVersion: Value(appVersion),
      syncStatus: Value(syncStatus),
      lastModifiedAt: Value(lastModifiedAt),
      createdAt: Value(createdAt),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'weekStart': weekStart.toIso8601String(),
      'mealsLogged': mealsLogged,
      'glucoseReadings': glucoseReadings,
      'manualReadings': manualReadings,
      'coveredMeals': coveredMeals,
      'uncoveredReasons': uncoveredReasons,
      'appVersion': appVersion,
      'syncStatus': syncStatus.name,
      'lastModifiedAt': lastModifiedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
