/// VitalSynch — Weekly Report Share Card (Infographic).
///
/// Branded 1080x1920 vertical card for Instagram Stories.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../charts/activity_rings.dart';
import '../health_score_gauge.dart';

/// Weekly report share card for social media.
///
/// Dimensions: 1080x1920 (9:16 ratio for Instagram Stories)
/// Features:
/// - VitalSynch branded header
/// - Health Score gauge
/// - Key metrics
/// - Activity Rings
/// - Top insight
/// - Tagline with date range
class WeeklyReportShareCard extends StatelessWidget {
  const WeeklyReportShareCard({
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
      height: 1920,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 60),

              // Health Score Gauge
              const Text(
                'Overall Wellness',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Center(child: HealthScoreGauge(score: healthScore, size: 300)),
              const SizedBox(height: 60),

              // Key Metrics
              _buildMetricsGrid(
                complianceRate: complianceRate,
                workoutCount: workoutCount,
                totalVolume: totalVolume,
                streakDays: streakDays,
              ),
              const SizedBox(height: 60),

              // Activity Rings
              Center(
                child: ActivityRings(
                  rings: [
                    ActivityRingData(
                      label: 'Health',
                      progress: complianceRate,
                      color: Colors.green,
                    ),
                    ActivityRingData(
                      label: 'Fitness',
                      progress: workoutConsistency,
                      color: Colors.orange,
                    ),
                    ActivityRingData(
                      label: 'Wellness',
                      progress: symptomInverse,
                      color: Colors.blue,
                    ),
                  ],
                  size: 280,
                ),
              ),

              const Spacer(),

              // Footer
              _buildFooter(dateFormat),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo placeholder
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.favorite, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 16),
        const Text(
          'VitalSynch',
          style: TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Health & Fitness Companion',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid({
    required double complianceRate,
    required int workoutCount,
    required double totalVolume,
    required int streakDays,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.medication,
                  label: 'Compliance',
                  value: '${(complianceRate * 100).toInt()}%',
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.fitness_center,
                  label: 'Workouts',
                  value: '$workoutCount',
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.trending_up,
                  label: 'Volume',
                  value: '${totalVolume.toInt()}kg',
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.local_fire_department,
                  label: 'Streak',
                  value: '$streakDays days',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 40),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(DateFormat dateFormat) {
    return Column(
      children: [
        Text(
          'My week with VitalSynch',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${dateFormat.format(weekStart)} - ${dateFormat.format(weekEnd)}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 20,
          ),
        ),
      ],
    );
  }
}
