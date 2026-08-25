/// VitalSync — Glucose Today Screen.
///
/// The last 24 hours of glucose measurements on one axis, with the meals
/// logged in the same window marked on it.
///
/// No comment, only measurement: the curve and the markers are drawn, and
/// the two counts below them are counts. Nothing on this screen relates a
/// meal to a reading, rates a value or draws a target range.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:vitalsync/core/enums/glucose_unit.dart';
import 'package:vitalsync/core/l10n/app_localizations.dart';
import 'package:vitalsync/core/theme/app_theme.dart';
import 'package:vitalsync/domain/entities/health/glucose_reading.dart';
import 'package:vitalsync/domain/entities/health/meal.dart';
import 'package:vitalsync/features/health/presentation/providers/glucose_provider.dart';
import 'package:vitalsync/features/health/presentation/providers/meal_provider.dart';
import 'package:vitalsync/features/health/presentation/widgets/glucose_timeline_chart.dart';
import 'package:vitalsync/presentation/widgets/glassmorphic_app_bar.dart';
import 'package:vitalsync/presentation/widgets/glassmorphic_card.dart';

class GlucoseTodayScreen extends ConsumerStatefulWidget {
  const GlucoseTodayScreen({super.key});

  @override
  ConsumerState<GlucoseTodayScreen> createState() => _GlucoseTodayScreenState();
}

class _GlucoseTodayScreenState extends ConsumerState<GlucoseTodayScreen> {
  /// The window is pinned when the screen opens so the chart, the readings
  /// and the meal markers all describe exactly the same 24 hours. Recomputing
  /// `DateTime.now()` per provider would let the two queries drift apart.
  late DateTime _windowEnd = DateTime.now();

  DateTime get _windowStart =>
      _windowEnd.subtract(const Duration(hours: 24));

  /// The chart is labelled in the storage unit; entry is where the user
  /// chooses how to type a value.
  static const _unit = GlucoseUnit.mgPerDl;

  Future<void> _refresh() async {
    setState(() => _windowEnd = DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final readingsAsync = ref.watch(
      glucoseReadingsInDateRangeProvider(
        startDate: _windowStart,
        endDate: _windowEnd,
      ),
    );
    final mealsAsync = ref.watch(
      mealsInDateRangeProvider(startDate: _windowStart, endDate: _windowEnd),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassmorphicAppBar(title: l10n.glucoseToday),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (readingsAsync.hasError || mealsAsync.hasError)
                  Center(
                    child: Text(
                      l10n.errorGeneric(
                        readingsAsync.error ?? mealsAsync.error!,
                      ),
                    ),
                  )
                else if (readingsAsync.isLoading || mealsAsync.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(48),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  ..._buildContent(
                    context,
                    l10n,
                    readingsAsync.requireValue,
                    mealsAsync.requireValue,
                  ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/health/glucose/add'),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.logGlucoseReading),
        backgroundColor: AppTheme.healthPrimary,
      ),
    );
  }

  List<Widget> _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    List<GlucoseReading> readings,
    List<Meal> meals,
  ) {
    final theme = Theme.of(context);

    if (readings.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: 64),
          child: Column(
            children: [
              Icon(
                Icons.show_chart_rounded,
                size: 48,
                color: theme.disabledColor.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(l10n.noGlucoseInWindow),
            ],
          ),
        ),
      ];
    }

    return [
      GlassmorphicCard(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
        child: GlucoseTimelineChart(
          points: readings
              .map(
                (r) => GlucosePoint(
                  measuredAt: r.measuredAt,
                  value: _unit.fromMgDl(r.valueMgDl),
                ),
              )
              .toList(),
          markers: meals
              .map((m) => MealMarker(eatenAt: m.eatenAt, label: m.name))
              .toList(),
          windowStart: _windowStart,
          windowEnd: _windowEnd,
          unitLabel: _unit.label,
          decimals: _unit.decimals,
          readingsLegendLabel: l10n.chartLegendReadings,
          mealsLegendLabel: l10n.chartLegendMeals,
        ),
      ),
      const SizedBox(height: 16),
      // Counts, not conclusions.
      Row(
        children: [
          Expanded(
            child: _CountTile(
              icon: Icons.water_drop_outlined,
              label: l10n.glucoseReadingCount(readings.length),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _CountTile(
              icon: Icons.restaurant_rounded,
              label: l10n.mealCount(meals.length),
            ),
          ),
        ],
      ),
    ];
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassmorphicCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
