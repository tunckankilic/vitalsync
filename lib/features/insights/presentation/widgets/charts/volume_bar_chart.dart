/// VitalSync — Volume Bar Chart with Ghost Bars.
///
/// Comparative bar chart showing current week vs previous week volume.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Data point for volume bar chart.
class VolumeDataPoint {
  const VolumeDataPoint({
    required this.day,
    required this.currentVolume,
    required this.previousVolume,
  });

  final String day;
  final double currentVolume;
  final double previousVolume;
}

/// Volume bar chart with ghost bars for comparison.
///
/// Features:
/// - Current week bars (solid)
/// - Previous week bars (ghost/transparent)
/// - Spring animation
/// - Touch tooltips
class VolumeBarChart extends StatelessWidget {
  const VolumeBarChart({required this.data, this.height = 200, super.key});

  final List<VolumeDataPoint> data;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (data.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No data available',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }

    final maxVolume = data.fold<double>(
      0,
      (max, point) => [
        max,
        point.currentVolume,
        point.previousVolume,
      ].reduce((a, b) => a > b ? a : b),
    );

    return SizedBox(
      height: height,
      child:
          BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxVolume * 1.2,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final point = data[groupIndex];
                        final isCurrent = rodIndex == 1;
                        final volume = isCurrent
                            ? point.currentVolume
                            : point.previousVolume;

                        return BarTooltipItem(
                          '${point.day}\n',
                          theme.textTheme.bodySmall!.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            TextSpan(
                              text: '${volume.toInt()}kg',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            TextSpan(
                              text: isCurrent ? ' (current)' : ' (previous)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
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
                          if (value.toInt() >= 0 &&
                              value.toInt() < data.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                data[value.toInt()].day,
                                style: theme.textTheme.bodySmall,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}',
                            style: theme.textTheme.bodySmall,
                          );
                        },
                      ),
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
                    horizontalInterval: maxVolume / 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: colorScheme.outline.withValues(alpha: 0.1),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: data.asMap().entries.map((entry) {
                    final index = entry.key;
                    final point = entry.value;

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        // Ghost bar (previous week)
                        BarChartRodData(
                          toY: point.previousVolume,
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        // Current week bar
                        BarChartRodData(
                          toY: point.currentVolume,
                          color: colorScheme.primary,
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(
                begin: 0.1,
                end: 0,
                duration: 600.ms,
                curve: Curves.easeOutBack,
              ),
    );
  }
}
