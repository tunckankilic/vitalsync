/// VitalSync — Trend Chart Widget.
///
/// Interactive line chart with ghost line for trend insights.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../../../presentation/widgets/glassmorphic_card.dart';

/// Data point for trend chart.
class TrendDataPoint {
  const TrendDataPoint({required this.date, required this.value});

  final DateTime date;
  final double value;
}

/// Interactive line chart with ghost line for trend comparison.
///
/// Features:
/// - Main trend line (current period)
/// - Ghost line (previous period comparison)
/// - Highlighted area showing trend direction
/// - Touch tooltip with date and value
/// - Animated transition when data changes
class TrendChart extends StatelessWidget {
  const TrendChart({
    required this.currentData,
    required this.previousData,
    this.currentColor,
    this.previousColor,
    this.title,
    super.key,
  });

  final List<TrendDataPoint> currentData;
  final List<TrendDataPoint> previousData;
  final Color? currentColor;
  final Color? previousColor;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveCurrentColor = currentColor ?? colorScheme.primary;
    final effectivePreviousColor =
        previousColor ?? colorScheme.onSurface.withValues(alpha: 0.3);

    // Calculate min and max values for Y axis
    final allValues = [
      ...currentData.map((e) => e.value),
      ...previousData.map((e) => e.value),
    ];
    final minY = allValues.reduce((a, b) => a < b ? a : b) * 0.9;
    final maxY = allValues.reduce((a, b) => a > b ? a : b) * 1.1;

    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              height: 200,
              child:
                  LineChart(
                        LineChartData(
                          minY: minY,
                          maxY: maxY,
                          lineTouchData: LineTouchData(
                            enabled: true,
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((spot) {
                                  final dataPoint = spot.barIndex == 0
                                      ? currentData[spot.spotIndex]
                                      : previousData[spot.spotIndex];
                                  final dateStr = DateFormat(
                                    'MMM d',
                                  ).format(dataPoint.date);
                                  final valueStr = dataPoint.value
                                      .toStringAsFixed(1);
                                  return LineTooltipItem(
                                    '$dateStr\n$valueStr',
                                    theme.textTheme.bodySmall!.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: (maxY - minY) / 5,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.1,
                                ),
                                strokeWidth: 1,
                              );
                            },
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                interval: (currentData.length / 4)
                                    .ceilToDouble(),
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index < 0 ||
                                      index >= currentData.length) {
                                    return const SizedBox.shrink();
                                  }
                                  final date = currentData[index].date;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      DateFormat('M/d').format(date),
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  );
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
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            // Current period line
                            LineChartBarData(
                              spots: currentData
                                  .asMap()
                                  .entries
                                  .map(
                                    (e) =>
                                        FlSpot(e.key.toDouble(), e.value.value),
                                  )
                                  .toList(),
                              isCurved: true,
                              color: effectiveCurrentColor,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 4,
                                    color: effectiveCurrentColor,
                                    strokeWidth: 2,
                                    strokeColor: colorScheme.surface,
                                  );
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                color: effectiveCurrentColor.withValues(
                                  alpha: 0.1,
                                ),
                              ),
                            ),
                            // Previous period ghost line
                            LineChartBarData(
                              spots: previousData
                                  .asMap()
                                  .entries
                                  .map(
                                    (e) =>
                                        FlSpot(e.key.toDouble(), e.value.value),
                                  )
                                  .toList(),
                              isCurved: true,
                              color: effectivePreviousColor,
                              barWidth: 2,
                              isStrokeCapRound: true,
                              dashArray: [5, 5],
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(show: false),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                      .slideX(
                        begin: -0.1,
                        end: 0,
                        duration: 600.ms,
                        curve: Curves.easeOutBack,
                      ),
            ),
            const SizedBox(height: 16),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(
                  color: effectiveCurrentColor,
                  label: 'Current Period',
                  isDashed: false,
                ),
                const SizedBox(width: 24),
                _LegendItem(
                  color: effectivePreviousColor,
                  label: 'Previous Period',
                  isDashed: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.isDashed,
  });

  final Color color;
  final String label;
  final bool isDashed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isDashed)
          CustomPaint(
            size: const Size(20, 2),
            painter: _DashedLinePainter(color: color),
          )
        else
          Container(
            width: 20,
            height: 2,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 3.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
