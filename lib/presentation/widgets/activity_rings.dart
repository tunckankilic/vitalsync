/// VitalSync — Activity Rings Widget.
///
/// Apple Health-style activity rings with:
/// - Three nested rings (fitness, health, insight)
/// - Animated ring fill with spring curve
/// - Module-specific colors from theme
/// - Center metric display
/// - Accessibility support
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/accessibility_helper.dart';

/// Apple Health-style activity rings widget.
///
/// Displays three nested rings representing:
/// - Outer ring (fitness): Workout progress
/// - Middle ring (health): Medication compliance
/// - Inner ring (insight): Health score
///
/// Features animated fill with spring curve.
class ActivityRings extends StatefulWidget {
  const ActivityRings({
    required this.fitnessProgress,
    required this.healthProgress,
    required this.insightProgress,
    this.centerMetric,
    this.centerLabel,
    this.onTap,
    this.size = 200,
    super.key,
  });

  /// Fitness ring progress (0.0 to 1.0)
  final double fitnessProgress;

  /// Health ring progress (0.0 to 1.0)
  final double healthProgress;

  /// Insight ring progress (0.0 to 1.0)
  final double insightProgress;

  /// Center metric text (e.g., "95%", "7")
  final String? centerMetric;

  /// Center label text (e.g., "streak", "compliance")
  final String? centerLabel;

  /// Tap callback
  final VoidCallback? onTap;

  /// Size of the rings widget
  final double size;

  @override
  State<ActivityRings> createState() => _ActivityRingsState();
}

class _ActivityRingsState extends State<ActivityRings>
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

    _animation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);

    // Start animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !AccessibilityHelper.shouldReduceMotion(context)) {
        _controller.forward();
      } else {
        // Skip animation if reduce motion is enabled
        _controller.value = 1.0;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label:
          'Activity Rings: '
          'Fitness ${(widget.fitnessProgress * 100).toStringAsFixed(0)}%, '
          'Health ${(widget.healthProgress * 100).toStringAsFixed(0)}%, '
          'Insight ${(widget.insightProgress * 100).toStringAsFixed(0)}%',
      button: widget.onTap != null,
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Rings
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _ActivityRingsPainter(
                      fitnessProgress:
                          widget.fitnessProgress * _animation.value,
                      healthProgress: widget.healthProgress * _animation.value,
                      insightProgress:
                          widget.insightProgress * _animation.value,
                    ),
                  );
                },
              ),
              // Center metric
              if (widget.centerMetric != null)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.centerMetric!,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.centerLabel != null)
                      Text(
                        widget.centerLabel!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityRingsPainter extends CustomPainter {
  _ActivityRingsPainter({
    required this.fitnessProgress,
    required this.healthProgress,
    required this.insightProgress,
  });

  final double fitnessProgress;
  final double healthProgress;
  final double insightProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final ringWidth = size.width * 0.08;
    final spacing = size.width * 0.04;

    // Outer ring (fitness - orange)
    _drawRing(
      canvas,
      center,
      size.width / 2 - ringWidth / 2,
      ringWidth,
      fitnessProgress,
      AppTheme.fitnessPrimary,
    );

    // Middle ring (health - green)
    _drawRing(
      canvas,
      center,
      size.width / 2 - ringWidth * 1.5 - spacing,
      ringWidth,
      healthProgress,
      AppTheme.healthPrimary,
    );

    // Inner ring (insight - blue)
    _drawRing(
      canvas,
      center,
      size.width / 2 - ringWidth * 2.5 - spacing * 2,
      ringWidth,
      insightProgress,
      AppTheme.insightPrimary,
    );
  }

  void _drawRing(
    Canvas canvas,
    Offset center,
    double radius,
    double strokeWidth,
    double progress,
    Color color,
  ) {
    // Background ring (gray)
    final backgroundPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress ring
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2; // Start from top
    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ActivityRingsPainter oldDelegate) {
    return oldDelegate.fitnessProgress != fitnessProgress ||
        oldDelegate.healthProgress != healthProgress ||
        oldDelegate.insightProgress != insightProgress;
  }
}
