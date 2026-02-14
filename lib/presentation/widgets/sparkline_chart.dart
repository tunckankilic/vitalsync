/// VitalSync — Sparkline Chart Widget.
///
/// Inline mini chart for trending data with:
/// - Compact line chart using CustomPainter
/// - Smooth line rendering with gradient fill
/// - Configurable height (30-40px)
/// - Responsive width
library;

import 'package:flutter/material.dart';

/// Compact sparkline chart for inline data visualization.
///
/// Displays a simple line chart for trending data (e.g., 7-day volume).
/// Features smooth line rendering with gradient fill.
class SparklineChart extends StatelessWidget {
  const SparklineChart({
    required this.data,
    this.height = 40,
    this.lineColor,
    this.fillGradient,
    super.key,
  });

  /// Data points to display (values should be normalized 0.0-1.0)
  final List<double> data;

  /// Height of the chart
  final double height;

  /// Line color (defaults to theme primary)
  final Color? lineColor;

  /// Fill gradient (optional)
  final Gradient? fillGradient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveLineColor = lineColor ?? theme.colorScheme.primary;

    if (data.isEmpty) {
      return SizedBox(height: height);
    }

    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _SparklinePainter(
          data: data,
          lineColor: effectiveLineColor,
          fillGradient: fillGradient,
        ),
        child: Container(),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.data,
    required this.lineColor,
    this.fillGradient,
  });

  final List<double> data;
  final Color lineColor;
  final Gradient? fillGradient;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final fillPath = Path();

    // Calculate point spacing
    final spacing = size.width / (data.length - 1);

    // Build line path
    for (var i = 0; i < data.length; i++) {
      final x = i * spacing;
      final y = size.height - (data[i].clamp(0.0, 1.0) * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Draw fill gradient if provided
    if (fillGradient != null) {
      fillPath.lineTo(size.width, size.height);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = fillGradient!.createShader(
          Rect.fromLTWH(0, 0, size.width, size.height),
        )
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw line
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillGradient != fillGradient;
  }
}
