/// VitalSync — Radial Progress Chart Widget.
///
/// Radial progress gauge for milestone insights.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../presentation/widgets/glassmorphic_card.dart';

/// Radial progress gauge widget.
///
/// Features:
/// - Animated fill with spring curve
/// - Large percentage in center
/// - Color gradient based on value
class RadialProgressChart extends StatefulWidget {
  const RadialProgressChart({
    required this.progress,
    required this.label,
    this.size = 200,
    this.strokeWidth = 20,
    this.lowColor,
    this.mediumColor,
    this.highColor,
    super.key,
  });

  final double progress; // 0.0 to 1.0
  final String label;
  final double size;
  final double strokeWidth;
  final Color? lowColor;
  final Color? mediumColor;
  final Color? highColor;

  @override
  State<RadialProgressChart> createState() => _RadialProgressChartState();
}

class _RadialProgressChartState extends State<RadialProgressChart>
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

    final effectiveLowColor = widget.lowColor ?? Colors.red;
    final effectiveMediumColor = widget.mediumColor ?? Colors.orange;
    final effectiveHighColor = widget.highColor ?? Colors.green;

    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                final animatedProgress = _animation.value * widget.progress;
                final progressColor = _getProgressColor(
                  widget.progress,
                  effectiveLowColor,
                  effectiveMediumColor,
                  effectiveHighColor,
                );

                return SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background circle
                      CustomPaint(
                        size: Size(widget.size, widget.size),
                        painter: _RadialProgressPainter(
                          progress: 1.0,
                          color: colorScheme.onSurface.withValues(alpha: 0.1),
                          strokeWidth: widget.strokeWidth,
                        ),
                      ),
                      // Progress circle
                      CustomPaint(
                        size: Size(widget.size, widget.size),
                        painter: _RadialProgressPainter(
                          progress: animatedProgress,
                          color: progressColor,
                          strokeWidth: widget.strokeWidth,
                        ),
                      ),
                      // Center text
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(widget.progress * 100).toInt()}%',
                            style: theme.textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: progressColor,
                            ),
                          ),
                          Text(
                            widget.label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getProgressColor(
    double progress,
    Color lowColor,
    Color mediumColor,
    Color highColor,
  ) {
    if (progress < 0.4) {
      return lowColor;
    } else if (progress < 0.7) {
      return mediumColor;
    } else {
      return highColor;
    }
  }
}

class _RadialProgressPainter extends CustomPainter {
  _RadialProgressPainter({
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
  bool shouldRepaint(covariant _RadialProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
