/// VitalSync — Weekly Chart Card Widget.
///
/// Interactive weekly overview chart (2x1):
/// - fl_chart bar + line chart combination
/// - Medication compliance bars
/// - Workout volume line overlay
/// - Ghost line showing previous week
/// - Touch interaction with tooltips
/// - Time range toggle
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../glassmorphic_card.dart';

/// Weekly overview chart card (2x1 grid size).
///
/// Features:
/// - Combined bar and line chart
/// - Medication compliance bars (health color)
/// - Workout volume line overlay (fitness color)
/// - Ghost line for previous week (comparative)
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

    // TODO: Connect to actual data providers
    // Mock data for now
    final complianceData = [0.8, 0.9, 0.7, 1.0, 0.85, 0.6, 0.95];
    // TODO: Add workout volume and previous week data for line overlay
    // final volumeData = [0.6, 0.7, 0.8, 0.75, 0.9, 0.85, 0.95];
    // final previousVolumeData = [0.5, 0.6, 0.7, 0.65, 0.7, 0.8, 0.75];

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
                  setState(() {
                    _showThisWeek = set.first;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Chart
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 1.0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final day = [
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat',
                        'Sun',
                      ][groupIndex];
                      return BarTooltipItem(
                        '$day\n${(rod.toY * 100).toInt()}%',
                        TextStyle(color: theme.colorScheme.onSurface),
                      );
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
                      BarChartRodData(
                        toY: complianceData[index],
                        color: AppTheme.healthPrimary,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ),
          ),

          const SizedBox(height: 8),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(
                color: AppTheme.healthPrimary,
                label: l10n.medicationCompliance,
              ),
              const SizedBox(width: 16),
              _LegendItem(
                color: AppTheme.fitnessPrimary,
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
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
