/// VitalSync — Workout Share Card (Story Format).
///
/// Branded 1080x1920 vertical card for Instagram Stories.
/// Shows workout name, date, key metrics, PRs, and VitalSync branding.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Workout share card for social media stories.
///
/// Dimensions: 1080x1920 (9:16 ratio for Instagram Stories)
class WorkoutShareCard extends StatelessWidget {
  const WorkoutShareCard({
    required this.workoutName,
    required this.date,
    required this.duration,
    required this.totalVolume,
    required this.totalSets,
    required this.exerciseCount,
    this.newPRs = const [],
    this.rating,
    super.key,
  });

  final String workoutName;
  final DateTime date;
  final Duration duration;
  final double totalVolume;
  final int totalSets;
  final int exerciseCount;
  final List<String> newPRs;
  final int? rating;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM d, yyyy').format(date);
    final ratingEmojis = ['😫', '😕', '😐', '😊', '🔥'];

    return Container(
      width: 1080,
      height: 1920,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 48),

            // Branded header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'VitalSync',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 64),

            // Workout name
            Text(
              workoutName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 56,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              dateStr,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 24,
              ),
            ),

            const SizedBox(height: 64),

            // Key Metrics Grid
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _MetricTile(
                          icon: Icons.timer_outlined,
                          value: _formatDuration(duration),
                          label: 'Duration',
                        ),
                      ),
                      Expanded(
                        child: _MetricTile(
                          icon: Icons.fitness_center,
                          value: '${totalVolume.toStringAsFixed(0)} kg',
                          label: 'Volume',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricTile(
                          icon: Icons.format_list_numbered,
                          value: '$totalSets',
                          label: 'Sets',
                        ),
                      ),
                      Expanded(
                        child: _MetricTile(
                          icon: Icons.sports_gymnastics,
                          value: '$exerciseCount',
                          label: 'Exercises',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // PRs Section
            if (newPRs.isNotEmpty) ...[
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text('🏆', style: TextStyle(fontSize: 28)),
                        SizedBox(width: 8),
                        Text(
                          'NEW PRs!',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...newPRs.map(
                      (pr) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          pr,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Rating
            if (rating != null && rating! >= 0 && rating! < 5) ...[
              const SizedBox(height: 32),
              Center(
                child: Text(
                  ratingEmojis[rating!],
                  style: const TextStyle(fontSize: 64),
                ),
              ),
            ],

            const Spacer(),

            // Footer
            Center(
              child: Text(
                'Tracked with VitalSync',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 20,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 32),
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

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFFF6B35), size: 32),
        const SizedBox(height: 8),
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
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
