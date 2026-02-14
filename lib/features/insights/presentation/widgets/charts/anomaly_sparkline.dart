/// VitalSync — Anomaly Sparkline Widget.
///
/// Sparkline with anomaly highlight for anomaly insights.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../presentation/widgets/glassmorphic_card.dart';

/// Data point for sparkline.
class SparklineDataPoint {
  const SparklineDataPoint({
    required this.index,
    required this.value,
    this.isAnomaly = false,
  });

  final int index;
  final double value;
  final bool isAnomaly;
}

/// Sparkline with anomaly highlight widget.
///
/// Features:
/// - Normal range band (gray area)
/// - Anomaly point with pulsing red dot
/// - Compact inline chart
class AnomalySparkline extends StatelessWidget {
  const AnomalySparkline({
    required this.data,
    required this.normalRangeMin,
    required this.normalRangeMax,
    this.height = 80,
    this.anomalyColor,
    super.key,
  });

  final List<SparklineDataPoint> data;
  final double normalRangeMin;
  final double normalRangeMax;
  final double height;
  final Color? anomalyColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveAnomalyColor = anomalyColor ?? Colors.red;

    // Calculate min and max values
    final allValues = data.map((e) => e.value).toList();
    final minValue = allValues.reduce((a, b) => a < b ? a : b) * 0.9;
    final maxValue = allValues.reduce((a, b) => a > b ? a : b) * 1.1;

    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child:
            SizedBox(
                  height: height,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _SparklinePainter(
                      data: data,
                      minValue: minValue,
                      maxValue: maxValue,
                      normalRangeMin: normalRangeMin,
                      normalRangeMax: normalRangeMax,
                      lineColor: colorScheme.primary,
                      normalRangeColor: colorScheme.onSurface.withValues(
                        alpha: 0.1,
                      ),
                      anomalyColor: effectiveAnomalyColor,
                    ),
                  ),
                )
                .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                )
                .fadeIn(duration: 400.ms, curve: Curves.easeOut),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.data,
    required this.minValue,
    required this.maxValue,
    required this.normalRangeMin,
    required this.normalRangeMax,
    required this.lineColor,
    required this.normalRangeColor,
    required this.anomalyColor,
  });

  final List<SparklineDataPoint> data;
  final double minValue;
  final double maxValue;
  final double normalRangeMin;
  final double normalRangeMax;
  final Color lineColor;
  final Color normalRangeColor;
  final Color anomalyColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final valueRange = maxValue - minValue;
    final xStep = size.width / (data.length - 1);

    // Draw normal range band
    final normalMinY =
        size.height - ((normalRangeMin - minValue) / valueRange * size.height);
    final normalMaxY =
        size.height - ((normalRangeMax - minValue) / valueRange * size.height);

    final normalRangePaint = Paint()
      ..color = normalRangeColor
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTRB(0, normalMaxY, size.width, normalMinY),
      normalRangePaint,
    );

    // Draw sparkline
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (var i = 0; i < data.length; i++) {
      final point = data[i];
      final x = i * xStep;
      final y =
          size.height - ((point.value - minValue) / valueRange * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);

    // Draw anomaly points
    final anomalyPaint = Paint()
      ..color = anomalyColor
      ..style = PaintingStyle.fill;

    final anomalyBorderPaint = Paint()
      ..color = anomalyColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    for (var i = 0; i < data.length; i++) {
      final point = data[i];
      if (point.isAnomaly) {
        final x = i * xStep;
        final y =
            size.height - ((point.value - minValue) / valueRange * size.height);

        // Pulsing border
        canvas.drawCircle(Offset(x, y), 8, anomalyBorderPaint);
        // Solid dot
        canvas.drawCircle(Offset(x, y), 4, anomalyPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.data != data;
  }
}
