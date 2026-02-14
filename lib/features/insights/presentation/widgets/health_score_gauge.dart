/// VitalSync — Health Score Gauge Widget.
///
/// Radial gauge displaying overall health score (0-100).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Health Score gauge widget.
///
/// Features:
/// - Radial gauge (0-100)
/// - Animated fill from 0 to target
/// - Color gradient: red (0-40), yellow (40-70), green (70-100)
/// - Large score number in center
/// - Calculation: compliance 40% + workout consistency 30% + symptom inverse 30%
class HealthScoreGauge extends StatefulWidget {
  const HealthScoreGauge({
    required this.score,
    this.size = 200,
    this.strokeWidth = 20,
    super.key,
  });

  final double score; // 0.0 to 1.0
  final double size;
  final double strokeWidth;

  @override
  State<HealthScoreGauge> createState() => _HealthScoreGaugeState();
}

class _HealthScoreGaugeState extends State<HealthScoreGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final animatedScore = _animation.value * widget.score;
        final scoreColor = _getScoreColor(widget.score);

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _GaugePainter(
                  progress: 1.0,
                  color: colorScheme.onSurface.withValues(alpha: 0.1),
                  strokeWidth: widget.strokeWidth,
                ),
              ),
              // Progress circle with gradient
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _GaugePainter(
                  progress: animatedScore,
                  color: scoreColor,
                  strokeWidth: widget.strokeWidth,
                ),
              ),
              // Center text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(widget.score * 100).toInt()}',
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                  Text(
                    'Health Score',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getScoreColor(double score) {
    if (score < 0.4) {
      // Red for low scores (0-40)
      return Colors.red;
    } else if (score < 0.7) {
      // Gradient from orange to yellow for medium scores (40-70)
      final t = (score - 0.4) / 0.3; // Normalize to 0-1
      return Color.lerp(Colors.orange, Colors.amber, t)!;
    } else {
      // Gradient from yellow-green to green for high scores (70-100)
      final t = (score - 0.7) / 0.3; // Normalize to 0-1
      return Color.lerp(Colors.lightGreen, Colors.green, t)!;
    }
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2; // Start at top
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
