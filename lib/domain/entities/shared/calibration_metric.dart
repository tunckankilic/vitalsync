import '../../../core/enums/sync_status.dart';

/// Weekly opt-in calibration counters.
///
/// **Counts only, no interpretation.** Every field is a tally of how much data
/// was recorded in one week. Nothing here states whether that is good, bad or
/// sufficient, and no glucose value itself is stored.
class CalibrationMetric {
  const CalibrationMetric({
    required this.id,
    required this.weekStart,
    required this.mealsLogged,
    required this.glucoseReadings,
    required this.manualReadings,
    required this.coveredMeals,
    required this.uncoveredReasons,
    required this.appVersion,
    required this.lastModifiedAt,
    required this.createdAt,
    this.syncStatus = SyncStatus.synced,
  });
  final int id;
  final DateTime weekStart;
  final int mealsLogged;
  final int glucoseReadings;
  final int manualReadings;
  final int coveredMeals;

  /// Counter map of why meals were not covered.
  /// Example: {"noReadingBefore": 3, "noReadingAfter": 1}
  final Map<String, int> uncoveredReasons;
  final String appVersion;
  final SyncStatus syncStatus;
  final DateTime lastModifiedAt;
  final DateTime createdAt;

  CalibrationMetric copyWith({
    int? id,
    DateTime? weekStart,
    int? mealsLogged,
    int? glucoseReadings,
    int? manualReadings,
    int? coveredMeals,
    Map<String, int>? uncoveredReasons,
    String? appVersion,
    SyncStatus? syncStatus,
    DateTime? lastModifiedAt,
    DateTime? createdAt,
  }) {
    return CalibrationMetric(
      id: id ?? this.id,
      weekStart: weekStart ?? this.weekStart,
      mealsLogged: mealsLogged ?? this.mealsLogged,
      glucoseReadings: glucoseReadings ?? this.glucoseReadings,
      manualReadings: manualReadings ?? this.manualReadings,
      coveredMeals: coveredMeals ?? this.coveredMeals,
      uncoveredReasons: uncoveredReasons ?? this.uncoveredReasons,
      appVersion: appVersion ?? this.appVersion,
      syncStatus: syncStatus ?? this.syncStatus,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CalibrationMetric &&
        other.id == id &&
        other.weekStart == weekStart &&
        other.mealsLogged == mealsLogged &&
        other.glucoseReadings == glucoseReadings &&
        other.manualReadings == manualReadings &&
        other.coveredMeals == coveredMeals &&
        other.uncoveredReasons.length == uncoveredReasons.length &&
        other.uncoveredReasons.entries.every(
          (e) => uncoveredReasons[e.key] == e.value,
        ) &&
        other.appVersion == appVersion &&
        other.syncStatus == syncStatus &&
        other.lastModifiedAt == lastModifiedAt &&
        other.createdAt == createdAt;
  }

  /// Hashes [uncoveredReasons] by its contents, matching how [operator ==]
  /// compares it. `Map.hashCode` is identity-based, so hashing it directly
  /// would let two equal metrics carry different hashes and break every
  /// `Set` and `Map` they are put into.
  @override
  int get hashCode {
    return id.hashCode ^
        weekStart.hashCode ^
        mealsLogged.hashCode ^
        glucoseReadings.hashCode ^
        manualReadings.hashCode ^
        coveredMeals.hashCode ^
        _uncoveredReasonsHash ^
        appVersion.hashCode ^
        syncStatus.hashCode ^
        lastModifiedAt.hashCode ^
        createdAt.hashCode;
  }

  /// Order-independent hash of the reason counts: two maps holding the same
  /// entries hash alike whatever order they were built in.
  int get _uncoveredReasonsHash {
    return Object.hashAllUnordered(
      uncoveredReasons.entries.map((e) => Object.hash(e.key, e.value)),
    );
  }

  @override
  String toString() {
    return 'CalibrationMetric(id: $id, weekStart: $weekStart, mealsLogged: $mealsLogged, glucoseReadings: $glucoseReadings, manualReadings: $manualReadings, coveredMeals: $coveredMeals, uncoveredReasons: $uncoveredReasons, appVersion: $appVersion, syncStatus: $syncStatus, lastModifiedAt: $lastModifiedAt, createdAt: $createdAt)';
  }
}
