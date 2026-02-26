/// VitalSync — Workout Compact Share Card.
///
/// Branded 1080x1080 square card for Instagram feed.
/// Minimal design with workout name and 3 key stats.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Compact workout share card for social media feed.
///
/// Dimensions: 1080x1080 (1:1 square for Instagram feed)
class WorkoutCompactCard extends StatelessWidget {
  const WorkoutCompactCard({
    required this.workoutName,
    required this.date,
    required this.duration,
    required this.totalVolume,
    required this.totalSets,
    super.key,
  });

  final String workoutName;
  final DateTime date;
  final Duration duration;
  final double totalVolume;
  final int totalSets;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM d, yyyy').format(date);

    return Container(
      width: 1080,
      height: 1080,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
        ),
        border: Border.all(
          color: const Color(0xFFFF6B35).withValues(alpha: 0.3),
          width: 4,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.fitness_center,
                color: Colors.white,
                size: 36,
              ),
            ),

            const SizedBox(height: 32),

            // Workout name
            Text(
              workoutName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 44,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              dateStr,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 20,
              ),
            ),

            const SizedBox(height: 48),

            // 3 key stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatColumn(
                  value: _formatDuration(duration),
                  label: 'Duration',
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                _StatColumn(
                  value: '${totalVolume.toStringAsFixed(0)} kg',
                  label: 'Volume',
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                _StatColumn(
                  value: '$totalSets',
                  label: 'Sets',
                ),
              ],
            ),

            const SizedBox(height: 48),

            // Footer
            Text(
              'Tracked with VitalSync',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
