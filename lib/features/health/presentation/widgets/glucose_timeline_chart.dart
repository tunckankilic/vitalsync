/// VitalSync — Glucose Timeline Chart.
///
/// Plots glucose measurements against time with meal markers on the same
/// axis.
///
/// No comment, only measurement: the chart draws the values that were
/// recorded and the times meals were logged. It carries no reference range,
/// no target band and no colour coding of "good" or "bad" — those are
/// clinical judgements and do not belong in this app.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/accessibility_helper.dart';

/// One plotted measurement.
class GlucosePoint {
  const GlucosePoint({required this.measuredAt, required this.value});

  /// When the measurement was taken.
  final DateTime measuredAt;

  /// The value, already converted to the unit the chart is labelled in.
  final double value;
}

/// One meal marker drawn as a vertical line.
class MealMarker {
  const MealMarker({required this.eatenAt, required this.label});

  final DateTime eatenAt;
  final String label;
}

/// Line chart of glucose measurements over a time window, with meal markers.
///
/// [points] and [markers] are expected in chronological order; the caller
/// sorts them (see `glucoseLast24HoursProvider`).
class GlucoseTimelineChart extends StatelessWidget {
  const GlucoseTimelineChart({
    required this.points,
    required this.markers,
    required this.windowStart,
    required this.windowEnd,
    required this.unitLabel,
    required this.mealsLegendLabel,
    required this.readingsLegendLabel,
    this.decimals = 0,
    super.key,
  });

  final List<GlucosePoint> points;
  final List<MealMarker> markers;
  final DateTime windowStart;
  final DateTime windowEnd;

  /// Unit suffix for the Y axis, e.g. "mg/dL". The caller has already
  /// converted [points] into this unit.
  final String unitLabel;
  final String mealsLegendLabel;
  final String readingsLegendLabel;

  /// Decimal places for Y axis labels and tooltips.
  final int decimals;

  /// Padding added above and below the observed value span so the line is
  /// not drawn flush against the chart edges. Expressed in the chart's own
  /// unit, not as a fraction, so a flat series still gets a usable axis.
  static const double _axisPadding = 10;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final lineColor = colorScheme.primary;
    final markerColor = colorScheme.tertiary;

    final totalMinutes = windowEnd
        .difference(windowStart)
        .inMinutes
        .toDouble();
    // A zero-width window would collapse the X axis and make fl_chart divide
    // by zero when spacing the bottom titles.
    final maxX = totalMinutes <= 0 ? 1.0 : totalMinutes;

    final values = points.map((p) => p.value).toList();
    final minValue = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a > b ? a : b);
    final minY = values.isEmpty ? 0.0 : minValue - _axisPadding;
    final maxY = values.isEmpty ? _axisPadding : maxValue + _axisPadding;

    final chart = LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final at = windowStart.add(
                  Duration(minutes: spot.x.round()),
                );
                final timeStr = DateFormat.Hm().format(at);
                final valueStr = spot.y.toStringAsFixed(decimals);
                return LineTooltipItem(
                  '$timeStr\n$valueStr $unitLabel',
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
          horizontalInterval: (maxY - minY) / 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: colorScheme.onSurface.withValues(alpha: 0.1),
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
              // One label every six hours over a 24 hour window.
              interval: maxX / 4,
              getTitlesWidget: (value, meta) {
                final at = windowStart.add(Duration(minutes: value.round()));
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat.Hm().format(at),
                    style: theme.textTheme.bodySmall,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              interval: (maxY - minY) / 4,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(decimals),
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
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          verticalLines: markers
              .map(
                (marker) => VerticalLine(
                  x: _minutesFromStart(marker.eatenAt, maxX),
                  color: markerColor.withValues(alpha: 0.6),
                  strokeWidth: 2,
                  dashArray: [4, 4],
                  label: VerticalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    style: theme.textTheme.labelSmall!.copyWith(
                      color: markerColor,
                      fontWeight: FontWeight.bold,
                    ),
                    labelResolver: (_) => marker.label,
                  ),
                ),
              )
              .toList(),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: points
                .map(
                  (p) => FlSpot(
                    _minutesFromStart(p.measuredAt, maxX),
                    p.value,
                  ),
                )
                .toList(),
            isCurved: true,
            color: lineColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: lineColor,
                  strokeWidth: 2,
                  strokeColor: colorScheme.surface,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: lineColor.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 220,
          child: chart
              .animate()
              .fadeIn(
                duration: AccessibilityHelper.getDuration(
                  context,
                  400.ms,
                ),
                curve: AccessibilityHelper.getCurve(context, Curves.easeOut),
              ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendItem(
              color: lineColor,
              label: readingsLegendLabel,
              isDashed: false,
            ),
            const SizedBox(width: 24),
            _LegendItem(
              color: markerColor,
              label: mealsLegendLabel,
              isDashed: true,
            ),
          ],
        ),
      ],
    );
  }

  /// Position of [at] on the X axis, clamped into the window so a marker
  /// sitting exactly on the boundary is still drawn.
  double _minutesFromStart(DateTime at, double maxX) {
    final minutes = at.difference(windowStart).inMinutes.toDouble();
    return minutes.clamp(0.0, maxX);
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
