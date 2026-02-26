/// VitalSync — Weekly Chart Card Widget.
///
/// Interactive weekly overview chart (2x1):
/// - fl_chart bar + line chart combination
/// - Medication compliance bars (current + ghost previous week)
/// - Workout volume line overlay
/// - Touch interaction with tooltips
/// - Time range toggle
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/fitness/presentation/providers/workout_provider.dart';
import '../../../features/health/presentation/providers/medication_log_provider.dart';
import '../glassmorphic_card.dart';

/// Weekly overview chart card (2x1 grid size).
///
/// Features:
/// - Combined bar chart with ghost bars for previous week
/// - Medication compliance bars (health color)
/// - Workout volume line overlay (fitness color)
/// - Ghost bars for previous week comparison
/// - Touch tooltips
/// - Time range toggle
class WeeklyChartCard extends ConsumerStatefulWidget {
  const WeeklyChartCard({super.key});

  @override
  ConsumerState<WeeklyChartCard> createState() => _WeeklyChartCardState();
}

class _WeeklyChartCardState extends ConsumerState<WeeklyChartCard> {
  bool _showThisWeek = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // Current week compliance data
    final complianceAsync = ref.watch(
      weekdayComplianceMapProvider(days: _showThisWeek ? 7 : 30),
    );
    final complianceData = complianceAsync.when(
      data: (map) => List.generate(7, (i) => map[i + 1] ?? 0.0),
      loading: () => List.filled(7, 0.0),
      error: (_, _) => List.filled(7, 0.0),
    );

    // Previous week compliance data (ghost)
    final prevComplianceAsync = ref.watch(
      weekdayComplianceMapProvider(days: _showThisWeek ? 14 : 60),
    );
    final prevComplianceData = prevComplianceAsync.when(
      data: (map) => List.generate(7, (i) => map[i + 1] ?? 0.0),
      loading: () => List.filled(7, 0.0),
      error: (_, _) => List.filled(7, 0.0),
    );

    // Workout volume data — compute daily volumes from recent workouts
    final recentWorkoutsAsync = ref.watch(recentWorkoutsProvider);
    final dailyVolume = recentWorkoutsAsync.when(
      data: (workouts) {
        final volumes = List.filled(7, 0.0);
        final now = DateTime.now();
        for (final w in workouts) {
          final daysDiff = now.difference(w.startTime).inDays;
          if (daysDiff < 7) {
            final weekday = w.startTime.weekday - 1; // 0=Mon, 6=Sun
            volumes[weekday] += w.totalVolume;
          }
        }
        // Normalize to 0-1 range for overlay
        final maxVol = volumes.reduce((a, b) => a > b ? a : b);
        if (maxVol > 0) {
          return volumes.map((v) => v / maxVol).toList();
        }
        return volumes;
      },
      loading: () => List.filled(7, 0.0),
      error: (_, _) => List.filled(7, 0.0),
    );

    return GlassmorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with time range toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.weeklyOverview,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: true,
                    label: Text(
                      l10n.thisWeek,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text(
                      l10n.last30Days,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
                selected: {_showThisWeek},
                onSelectionChanged: (set) {
                  setState(() => _showThisWeek = set.first);
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Combined chart with bars + line overlay
          Expanded(
            child: BarChart(
              swapAnimationDuration: const Duration(milliseconds: 300),
              swapAnimationCurve: Curves.easeInOut,
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 1.0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final day = [
                        'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
                      ][groupIndex];
                      if (rodIndex == 0) {
                        return BarTooltipItem(
                          '$day\n${(rod.toY * 100).toInt()}%',
                          TextStyle(color: theme.colorScheme.onSurface),
                        );
                      }
                      return null;
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Text(
                            days[value.toInt()],
                            style: theme.textTheme.bodySmall,
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 0.25,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  7,
                  (index) => BarChartGroupData(
                    x: index,
                    barRods: [
                      // Current week compliance (main bar)
                      BarChartRodData(
                        toY: complianceData[index],
                        color: AppTheme.healthPrimary,
                        width: 12,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                      // Previous week compliance (ghost bar)
                      BarChartRodData(
                        toY: prevComplianceData[index],
                        color: AppTheme.healthPrimary.withValues(alpha: 0.2),
                        width: 6,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                      // Workout volume (fitness bar)
                      BarChartRodData(
                        toY: dailyVolume[index],
                        color: AppTheme.fitnessPrimary.withValues(alpha: 0.7),
                        width: 6,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                    barsSpace: 2,
                  ),
                ),
              ),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ),
          ),

          const SizedBox(height: 8),

          // Legend (3 items)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(
                color: AppTheme.healthPrimary,
                label: l10n.medicationCompliance,
              ),
              const SizedBox(width: 8),
              _LegendItem(
                color: AppTheme.healthPrimary.withValues(alpha: 0.2),
                label: l10n.previousWeek,
              ),
              const SizedBox(width: 8),
              _LegendItem(
                color: AppTheme.fitnessPrimary.withValues(alpha: 0.7),
                label: l10n.workoutVolume,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
        ),
      ],
    );
  }
}
