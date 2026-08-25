/// VitalSync — Meal Data Coverage Service.
///
/// **This service measures data completeness only. It does not produce a
/// score, an iAUC, or any glycaemic interpretation, and it must not — that
/// logic belongs to a separate product.**
///
/// Its single question is: was enough measurement data recorded around this
/// meal? The answer is `covered` or `uncovered` plus a reason. It never says
/// anything about the values themselves, and never relates a meal to a
/// reading beyond counting whether readings exist.
library;

import '../../../../core/enums/glucose_source.dart';
import '../../../../core/enums/health_sample_type.dart';
import '../../../../domain/entities/health/glucose_reading.dart';
import '../../../../domain/entities/health/health_sample.dart';
import '../../../../domain/entities/health/meal.dart';
import '../../../../domain/repositories/health/glucose_repository.dart';
import '../../../../domain/repositories/health/health_sample_repository.dart';
import '../../../../domain/repositories/health/meal_repository.dart';

/// Why a meal's window did not hold enough data.
enum UncoveredReason {
  /// Fewer than [MealDataCoverageService.minimumReadingsInWindow] readings
  /// fell in the window — including the case of none at all.
  noReadings,

  /// Enough readings, but they leave a gap wider than
  /// [MealDataCoverageService.maximumReadingGap].
  gapInData,

  /// Another meal was logged close enough to share the window.
  overlappingMeal,

  /// Enough recorded activity fell in the window to change what the window
  /// is measuring.
  activityInWindow,
}

/// The coverage verdict for one meal.
class MealCoverage {
  const MealCoverage.covered(this.mealId) : reason = null;

  const MealCoverage.uncovered(this.mealId, UncoveredReason this.reason);

  final int mealId;

  /// Null when the meal is covered.
  final UncoveredReason? reason;

  bool get isCovered => reason == null;

  @override
  String toString() => 'MealCoverage(mealId: $mealId, reason: $reason)';
}

/// Tallies over a set of [MealCoverage] verdicts.
///
/// Counts only — nothing here reads as a judgement on the numbers.
class MealCoverageSummary {
  const MealCoverageSummary({
    required this.mealsEvaluated,
    required this.coveredMeals,
    required this.uncoveredReasons,
  });

  factory MealCoverageSummary.from(List<MealCoverage> coverages) {
    final reasons = <UncoveredReason, int>{};
    var covered = 0;

    for (final coverage in coverages) {
      if (coverage.isCovered) {
        covered++;
      } else {
        final reason = coverage.reason!;
        reasons[reason] = (reasons[reason] ?? 0) + 1;
      }
    }

    return MealCoverageSummary(
      mealsEvaluated: coverages.length,
      coveredMeals: covered,
      uncoveredReasons: Map.unmodifiable(reasons),
    );
  }

  final int mealsEvaluated;
  final int coveredMeals;
  final Map<UncoveredReason, int> uncoveredReasons;

  int get uncoveredMeals => mealsEvaluated - coveredMeals;

  /// The reason tallies keyed by enum name, the shape the calibration
  /// metrics row stores.
  Map<String, int> reasonsByName() {
    return {
      for (final entry in uncoveredReasons.entries)
        entry.key.name: entry.value,
    };
  }

  @override
  String toString() {
    return 'MealCoverageSummary(evaluated: $mealsEvaluated, '
        'covered: $coveredMeals, reasons: $uncoveredReasons)';
  }
}

/// Decides whether each meal has enough measurement data around it.
///
/// Deterministic and side-effect free: given the same meals, readings and
/// samples it always returns the same verdicts.
class MealDataCoverageService {
  MealDataCoverageService({
    required MealRepository mealRepository,
    required GlucoseRepository glucoseRepository,
    required HealthSampleRepository healthSampleRepository,
  }) : _mealRepository = mealRepository,
       _glucoseRepository = glucoseRepository,
       _healthSampleRepository = healthSampleRepository;

  final MealRepository _mealRepository;
  final GlucoseRepository _glucoseRepository;
  final HealthSampleRepository _healthSampleRepository;

  // ── Thresholds ──────────────────────────────────────────────────────
  //
  // Starting values, to be calibrated against real usage once the opt-in
  // metrics come back. Named on purpose: no magic numbers in the logic
  // below.

  /// How long after a meal the window runs.
  static const Duration postMealWindow = Duration(hours: 2);

  /// How much clear time a meal needs on either side of its window before
  /// another meal is considered to share it.
  static const Duration mealSeparation = Duration(hours: 1);

  /// How many readings the window must hold.
  static const int minimumReadingsInWindow = 3;

  /// The widest acceptable stretch of the window without a reading, counting
  /// the run-up from the meal and the tail to the end of the window.
  ///
  /// Sized against the two constants above: a 2 hour window holding the
  /// minimum 3 readings is exactly satisfiable at 0, 60 and 120 minutes.
  static const Duration maximumReadingGap = Duration(minutes: 60);

  /// Active energy in the window, above which the window is treated as
  /// carrying activity.
  static const double activeEnergyThresholdKcal = 150;

  // ── Public API ──────────────────────────────────────────────────────

  /// Evaluates every meal logged in [start] .. [end].
  Future<List<MealCoverage>> evaluateRange(
    DateTime start,
    DateTime end,
  ) async {
    return evaluateMeals(await _mealRepository.getByDateRange(start, end));
  }

  /// Evaluates [meals], loading the surrounding data each one needs.
  ///
  /// Reads a little beyond the span of [meals] on both sides: the last meal
  /// still needs its window, and a meal just outside the span can still be
  /// the neighbour that makes one inside it uncovered.
  Future<List<MealCoverage>> evaluateMeals(List<Meal> meals) async {
    if (meals.isEmpty) return const [];

    final times = meals.map((m) => m.eatenAt).toList()..sort();
    final from = times.first.subtract(mealSeparation);
    final windowEnd = times.last.add(postMealWindow);

    final contextMeals = await _mealRepository.getByDateRange(
      from,
      windowEnd.add(mealSeparation),
    );
    final readings = await _glucoseRepository.getByDateRange(
      times.first,
      windowEnd,
    );
    final samples = await _healthSampleRepository.getByDateRange(
      times.first,
      windowEnd,
    );

    return meals
        .map(
          (meal) => evaluateMeal(
            meal: meal,
            otherMeals: contextMeals,
            readings: readings,
            samples: samples,
          ),
        )
        .toList();
  }

  /// Evaluates every meal logged in the week starting at [weekStart].
  Future<MealCoverageSummary> summarizeWeek(DateTime weekStart) async {
    final coverages = await evaluateRange(
      weekStart,
      weekStart.add(const Duration(days: 7)),
    );
    return MealCoverageSummary.from(coverages);
  }

  /// Decides one meal's coverage against the data it is given.
  ///
  /// Pure: [otherMeals], [readings] and [samples] may span any range; only
  /// the entries falling in this meal's window are considered. [otherMeals]
  /// may include [meal] itself, which is skipped.
  ///
  /// Reasons are checked in a fixed order, and the first match wins:
  /// [UncoveredReason.overlappingMeal] and
  /// [UncoveredReason.activityInWindow] come first because they invalidate
  /// the window itself, ahead of whatever was or was not measured inside it.
  MealCoverage evaluateMeal({
    required Meal meal,
    required List<Meal> otherMeals,
    required List<GlucoseReading> readings,
    required List<HealthSample> samples,
  }) {
    final windowStart = meal.eatenAt;
    final windowEnd = windowStart.add(postMealWindow);

    if (_hasNeighbouringMeal(meal, otherMeals, windowEnd)) {
      return MealCoverage.uncovered(
        meal.id,
        UncoveredReason.overlappingMeal,
      );
    }

    if (_hasActivity(samples, windowStart, windowEnd)) {
      return MealCoverage.uncovered(
        meal.id,
        UncoveredReason.activityInWindow,
      );
    }

    final inWindow =
        readings
            .where(
              (r) =>
                  !r.measuredAt.isBefore(windowStart) &&
                  !r.measuredAt.isAfter(windowEnd),
            )
            .toList()
          ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

    if (inWindow.length < minimumReadingsInWindow) {
      return MealCoverage.uncovered(meal.id, UncoveredReason.noReadings);
    }

    if (_hasGap(inWindow, windowStart, windowEnd)) {
      return MealCoverage.uncovered(meal.id, UncoveredReason.gapInData);
    }

    return MealCoverage.covered(meal.id);
  }

  // ── Checks ──────────────────────────────────────────────────────────

  /// Whether another meal sits close enough to share this meal's window.
  bool _hasNeighbouringMeal(
    Meal meal,
    List<Meal> otherMeals,
    DateTime windowEnd,
  ) {
    final from = meal.eatenAt.subtract(mealSeparation);
    final to = windowEnd.add(mealSeparation);

    return otherMeals.any(
      (other) =>
          other.id != meal.id &&
          !other.eatenAt.isBefore(from) &&
          !other.eatenAt.isAfter(to),
    );
  }

  /// Whether the window carries a recorded workout, or active energy above
  /// [activeEnergyThresholdKcal].
  bool _hasActivity(
    List<HealthSample> samples,
    DateTime windowStart,
    DateTime windowEnd,
  ) {
    var activeEnergy = 0.0;

    for (final sample in samples) {
      if (!_overlapsWindow(sample, windowStart, windowEnd)) continue;

      switch (sample.type) {
        case HealthSampleType.workout:
          return true;
        case HealthSampleType.activeEnergy:
          activeEnergy += sample.value;
        case HealthSampleType.steps:
        case HealthSampleType.sleep:
          break;
      }
    }

    return activeEnergy > activeEnergyThresholdKcal;
  }

  /// Whether an interval sample touches the window at all.
  ///
  /// Instantaneous samples carry no [HealthSample.endAt]; they are treated
  /// as zero-length at [HealthSample.startAt].
  bool _overlapsWindow(
    HealthSample sample,
    DateTime windowStart,
    DateTime windowEnd,
  ) {
    final sampleEnd = sample.endAt ?? sample.startAt;
    return !sampleEnd.isBefore(windowStart) &&
        !sample.startAt.isAfter(windowEnd);
  }

  /// Whether the readings leave a stretch wider than [maximumReadingGap].
  ///
  /// The run-up from the meal to the first reading and the tail from the
  /// last reading to the end of the window count as gaps too — otherwise
  /// three readings bunched into ten minutes would pass for a covered
  /// two-hour window.
  bool _hasGap(
    List<GlucoseReading> sortedReadings,
    DateTime windowStart,
    DateTime windowEnd,
  ) {
    var previous = windowStart;

    for (final reading in sortedReadings) {
      if (reading.measuredAt.difference(previous) > maximumReadingGap) {
        return true;
      }
      previous = reading.measuredAt;
    }

    return windowEnd.difference(previous) > maximumReadingGap;
  }
}

/// Counts of readings by origin, for the calibration metrics row.
///
/// Lives here so the one place that knows what a "manual" reading is stays
/// the one place that counts them.
extension GlucoseReadingCounts on List<GlucoseReading> {
  int get manualCount =>
      where((r) => r.source == GlucoseSource.manual).length;
}
