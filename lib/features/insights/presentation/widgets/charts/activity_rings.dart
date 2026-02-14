/// VitalSync — Activity Rings Widget.
///
/// Apple Watch-style activity rings for health and fitness tracking.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Activity rings data.
class ActivityRingData {
  const ActivityRingData({
    required this.label,
    required this.progress,
    required this.color,
    this.goal,
  });

  final String label;
  final double progress; // 0.0 to 1.0
  final Color color;
  final String? goal;
}

/// Activity rings widget with animated progress.
///
/// Features:
/// - Three concentric rings
/// - Animated fill with spring curve
/// - Touch to show details
/// - Comparison mode (current vs previous)
class ActivityRings extends StatelessWidget {
  const ActivityRings({
    required this.rings,
    this.size = 200,
    this.strokeWidth = 16,
    this.showComparison = false,
    this.previousRings,
    super.key,
  });

  final List<ActivityRingData> rings;
  final double size;
  final double strokeWidth;
  final bool showComparison;
  final List<ActivityRingData>? previousRings;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main rings
        SizedBox(
              width: size,
              height: size,
              child: CustomPaint(
                painter: _ActivityRingsPainter(
                  rings: rings,
                  strokeWidth: strokeWidth,
                ),
              ),
            )
            .animate()
            .fadeIn(duration: 400.ms)
            .scale(
              begin: const Offset(0.8, 0.8),
              duration: 600.ms,
              curve: Curves.easeOutBack,
            ),

        const SizedBox(height: 16),

        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: rings.map((ring) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: ring.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${ring.label}: ${(ring.progress * 100).toInt()}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            );
          }).toList(),
        ),

        // Comparison rings (if enabled)
        if (showComparison && previousRings != null) ...[
          const SizedBox(height: 20),
          Text(
            'vs Last Week',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Previous week (mini)
              SizedBox(
                width: size * 0.4,
                height: size * 0.4,
                child: CustomPaint(
                  painter: _ActivityRingsPainter(
                    rings: previousRings!,
                    strokeWidth: strokeWidth * 0.6,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.arrow_forward,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 16),
              // Current week (mini)
              SizedBox(
                width: size * 0.4,
                height: size * 0.4,
                child: CustomPaint(
                  painter: _ActivityRingsPainter(
                    rings: rings,
                    strokeWidth: strokeWidth * 0.6,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ActivityRingsPainter extends CustomPainter {
  _ActivityRingsPainter({required this.rings, required this.strokeWidth});

  final List<ActivityRingData> rings;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2 - strokeWidth / 2;

    for (var i = 0; i < rings.length; i++) {
      final ring = rings[i];
      final radius = maxRadius - (i * (strokeWidth + 4));

      // Background ring (gray)
      final backgroundPaint = Paint()
        ..color = ring.color.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawCircle(center, radius, backgroundPaint);

      // Progress ring
      final progressPaint = Paint()
        ..color = ring.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      const startAngle = -math.pi / 2; // Start from top
      final sweepAngle = 2 * math.pi * ring.progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ActivityRingsPainter oldDelegate) {
    return oldDelegate.rings != rings;
  }
}
