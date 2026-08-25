/// VitalSync — Calibration Metrics Service.
///
/// **Counts only, no interpretation.** Collects one weekly row of tallies —
/// how many meals, how many readings, how many of those were typed by hand,
/// how many meals had enough data around them and why the rest did not.
///
/// No health data ever reaches this row: no glucose value, no meal name, no
/// note. Every field is an integer, a date or the app version.
///
/// The collection is opt-in. While consent is off nothing is produced —
/// [collectForWeek] returns null before it reads anything, so there is no
/// row to withhold.
library;

import '../../../../core/enums/sync_status.dart';
import '../../../../domain/entities/shared/calibration_metric.dart';
import '../../../../domain/repositories/health/glucose_repository.dart';
import '../../../../domain/repositories/health/meal_repository.dart';
import '../../../../domain/repositories/shared/calibration_metric_repository.dart';
import 'meal_data_coverage_service.dart';

class CalibrationMetricsService {
  CalibrationMetricsService({
    required MealDataCoverageService coverageService,
    required MealRepository mealRepository,
    required GlucoseRepository glucoseRepository,
    required CalibrationMetricRepository metricRepository,
    required bool Function() isConsentGranted,
    required String appVersion,
  }) : _coverageService = coverageService,
       _mealRepository = mealRepository,
       _glucoseRepository = glucoseRepository,
       _metricRepository = metricRepository,
       _isConsentGranted = isConsentGranted,
       _appVersion = appVersion;

  final MealDataCoverageService _coverageService;
  final MealRepository _mealRepository;
  final GlucoseRepository _glucoseRepository;
  final CalibrationMetricRepository _metricRepository;

  /// Whether the user has turned calibration metrics on.
  ///
  /// Passed in rather than read from [GDPRManager] directly: the weekly
  /// collection also runs in the WorkManager isolate, where that manager's
  /// dependencies are not available. The app supplies a manager-backed
  /// reader, the background task a preferences-backed one.
  final bool Function() _isConsentGranted;

  final String _appVersion;

  /// Collects and stores the counters for the week starting at [weekStart].
  ///
  /// Returns null — and touches no repository — when consent is off.
  /// Re-running for a week that already has a row updates that row instead
  /// of adding a second one, so a retried background task cannot double
  /// count.
  Future<CalibrationMetric?> collectForWeek(DateTime weekStart) async {
    if (!_isConsentGranted()) return null;

    final weekEnd = weekStart.add(const Duration(days: 7));

    final meals = await _mealRepository.getByDateRange(weekStart, weekEnd);
    final readings = await _glucoseRepository.getByDateRange(
      weekStart,
      weekEnd,
    );
    final coverage = await _coverageService.summarizeWeek(weekStart);

    final now = DateTime.now();
    final existing = await _metricRepository.getByWeekStart(weekStart);

    final metric = CalibrationMetric(
      id: existing?.id ?? 0,
      weekStart: weekStart,
      mealsLogged: meals.length,
      glucoseReadings: readings.length,
      manualReadings: readings.manualCount,
      coveredMeals: coverage.coveredMeals,
      uncoveredReasons: coverage.reasonsByName(),
      appVersion: _appVersion,
      syncStatus: SyncStatus.pending,
      lastModifiedAt: now,
      createdAt: existing?.createdAt ?? now,
    );

    if (existing == null) {
      final id = await _metricRepository.insert(metric);
      return metric.copyWith(id: id);
    }

    await _metricRepository.update(metric);
    return metric;
  }
}
