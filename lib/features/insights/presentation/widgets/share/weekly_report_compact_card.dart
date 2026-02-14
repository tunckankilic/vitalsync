/// VitalSync — Weekly Report Compact Share Card.
///
/// Branded 1080x1080 square card for general social sharing.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Compact weekly report share card.
///
/// Dimensions: 1080x1080 (1:1 ratio)
/// Features:
/// - Compact layout
/// - Key metrics in grid
/// - Health score badge
/// - VitalSync branding
class WeeklyReportCompactCard extends StatelessWidget {
  const WeeklyReportCompactCard({
    required this.report,
    required this.weekStart,
    required this.weekEnd,
    super.key,
  });

  final Map<String, dynamic> report;
  final DateTime weekStart;
  final DateTime weekEnd;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d');
    final complianceRate = (report['compliance_rate'] as num?)?.toDouble() ?? 0;
    final workoutCount = (report['workout_count'] as int?) ?? 0;
    final totalVolume = (report['total_volume'] as num?)?.toDouble() ?? 0;
    final streakDays = (report['streak_days'] as int?) ?? 0;

    // Calculate health score
    final workoutConsistency = (workoutCount / 7).clamp(0.0, 1.0);
    final symptomCount = (report['symptom_count'] as int?) ?? 0;
    final symptomInverse = 1.0 - (symptomCount / 10).clamp(0.0, 1.0);
    final healthScore =
        complianceRate * 0.4 + workoutConsistency * 0.3 + symptomInverse * 0.3;

    return Container(
      width: 1080,
      height: 1080,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'VitalSync',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Weekly Report',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),

            // Health Score Badge
            Center(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _getScoreColor(healthScore),
                      _getScoreColor(healthScore).withValues(alpha: 0.5),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getScoreColor(healthScore).withValues(alpha: 0.5),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${(healthScore * 100).toInt()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 96,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Health Score',
                        style: TextStyle(color: Colors.white, fontSize: 24),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 60),

            // Metrics Grid
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetric(
                    icon: Icons.medication,
                    value: '${(complianceRate * 100).toInt()}%',
                    label: 'Compliance',
                  ),
                  _buildMetric(
                    icon: Icons.fitness_center,
                    value: '$workoutCount',
                    label: 'Workouts',
                  ),
                  _buildMetric(
                    icon: Icons.trending_up,
                    value: '${totalVolume.toInt()}kg',
                    label: 'Volume',
                  ),
                  _buildMetric(
                    icon: Icons.local_fire_department,
                    value: '$streakDays',
                    label: 'Streak',
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Footer
            Text(
              '${dateFormat.format(weekStart)} - ${dateFormat.format(weekEnd)}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 24,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 40),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.7) return Colors.green;
    if (score >= 0.4) return Colors.orange;
    return Colors.red;
  }
}
