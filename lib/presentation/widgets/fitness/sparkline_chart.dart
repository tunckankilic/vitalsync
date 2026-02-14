/// VitalSync — Sparkline Chart Component
///
/// Mini inline trend chart for displaying compact data visualizations.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// A compact sparkline chart for showing trends inline.
///
/// Displays a simple line chart without axes or labels, perfect for
/// showing trends in a small space.
class SparklineChart extends StatelessWidget {
  /// Creates a sparkline chart.
  const SparklineChart({
    required this.data,
    this.color,
    this.height = 30,
    this.lineWidth = 2,
    this.showDots = false,
    super.key,
  });

  /// Data points to display (y-values, x is implicit).
  final List<double> data;

  /// Color of the line.
  final Color? color;

  /// Height of the chart.
  final double height;

  /// Width of the line.
  final double lineWidth;

  /// Whether to show dots at data points.
  final bool showDots;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lineColor = color ?? theme.colorScheme.primary;

    if (data.isEmpty) {
      return SizedBox(height: height);
    }

    // Normalize data to 0-1 range for consistent display
    final minValue = data.reduce((a, b) => a < b ? a : b);
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue;

    final spots = data.asMap().entries.map((entry) {
      final normalizedY = range > 0 ? (entry.value - minValue) / range : 0.5;
      return FlSpot(entry.key.toDouble(), normalizedY);
    }).toList();

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (data.length - 1).toDouble(),
          minY: 0,
          maxY: 1,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: lineColor,
              barWidth: lineWidth,
              isStrokeCapRound: true,
              dotData: FlDotData(show: showDots),
              belowBarData: BarAreaData(show: false),
            ),
          ],
          lineTouchData: const LineTouchData(enabled: false),
        ),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
      ),
    );
  }
}
