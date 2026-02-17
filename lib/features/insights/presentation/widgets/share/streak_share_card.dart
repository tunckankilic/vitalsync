/// VitalSynch — Streak Share Card.
///
/// Branded streak milestone card with fire effect.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Streak share card for milestone celebrations.
///
/// Dimensions: 1080x1080
/// Features:
/// - Large streak number with fire effect
/// - Milestone badge
/// - Date range
/// - VitalSynch branding
class StreakShareCard extends StatelessWidget {
  const StreakShareCard({
    required this.streakDays,
    required this.startDate,
    required this.endDate,
    super.key,
  });

  final int streakDays;
  final DateTime startDate;
  final DateTime endDate;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Container(
      width: 1080,
      height: 1080,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
            Color(0xFF0F3460),
            Color(0xFF1A1A2E),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Fire effect background
          Positioned.fill(child: CustomPaint(painter: _FireEffectPainter())),

          // Content
          Padding(
            padding: const EdgeInsets.all(60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Fire emoji
                const Text('🔥', style: TextStyle(fontSize: 120)),
                const SizedBox(height: 40),

                // Streak number
                Text(
                  '$streakDays',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 240,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.orange.withValues(alpha: 0.8),
                        blurRadius: 40,
                      ),
                      Shadow(
                        color: Colors.red.withValues(alpha: 0.6),
                        blurRadius: 80,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.orange, Colors.deepOrange],
                    ),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Text(
                    '$streakDays Day Streak',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 60),

                // Date range
                Text(
                  '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 80),

                // VitalSynch branding
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'VitalSynch',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Health & Fitness Companion',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for fire effect background.
class _FireEffectPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Create radial gradient for glow effect
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 0.8,
      colors: [
        Colors.orange.withValues(alpha: 0.3),
        Colors.red.withValues(alpha: 0.2),
        Colors.transparent,
      ],
    );

    paint.shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
