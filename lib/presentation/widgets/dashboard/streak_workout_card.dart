/// VitalSync — Streak & Workout Card Widget.
///
/// Streak and last workout mini card (1x1):
/// - Fire emoji with streak number
/// - Animated glow on milestone days
/// - Last workout info or "Start Workout" CTA
/// - Sparkline chart (7-day volume trend)
/// - Tap navigation to Fitness tab
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/extensions.dart';

import '../../../features/fitness/presentation/providers/progress_provider.dart';
import '../../../features/fitness/presentation/providers/streak_provider.dart';
import '../../../presentation/providers/dashboard_provider.dart';
import '../glassmorphic_card.dart';
import '../sparkline_chart.dart';

/// Streak & Last Workout mini card (1x1 grid size).
///
/// Features:
/// - Streak count with fire emoji
/// - Animated glow on milestones (7, 14, 30, 60, 100)
/// - Last workout info or Start Workout CTA
/// - Sparkline chart for 7-day volume trend
/// - Tap to navigate to Fitness tab
class StreakWorkoutCard extends ConsumerWidget {
  const StreakWorkoutCard({super.key});

  // Milestone days for glow effect
  static const milestones = [7, 14, 30, 60, 100];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final streakAsync = ref.watch(currentStreakProvider);
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return GlassmorphicCard(
      child: InkWell(
        onTap: () => context.go('/fitness'),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Streak with fire emoji
            streakAsync.when(
              data: (streak) {
                final isMilestone = milestones.contains(streak);
                return Row(
                  children: [
                    Text(
                      '🔥',
                      style: TextStyle(
                        fontSize: 32,
                        shadows: isMilestone
                            ? [
                                const Shadow(
                                  color: AppTheme.fitnessSecondary,
                                  blurRadius: 20,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$streak',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.fitnessPrimary,
                      ),
                    ),
                  ],
                );
              },
              loading: () => const SizedBox(height: 40),
              error: (_, _) => const SizedBox(height: 40),
            ),

            const SizedBox(height: 4),

            // Streak label
            Text(
              l10n.currentStreak,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),

            const Spacer(),

            // Last workout or CTA
            summaryAsync.when(
              data: (summary) {
                if (summary.lastWorkout != null) {
                  final workout = summary.lastWorkout!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        workout.endTime != null
                            ? workout.endTime!.formatRelative(context)
                            : l10n.inProgress,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  return ElevatedButton.icon(
                    onPressed: () => context.push('/fitness/workout/start'),
                    icon: const Icon(Icons.fitness_center, size: 18),
                    label: Text(l10n.startWorkout),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.fitnessPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  );
                }
              },
              loading: () => const SizedBox(height: 40),
              error: (_, _) => const SizedBox(height: 40),
            ),

            const SizedBox(height: 8),

            // 7-day volume sparkline from provider
            SparklineChart(
              data: ref.watch(volumeChartDataProvider(TimeRange.oneWeek)).when(
                data: (points) {
                  if (points.isEmpty) return const [0.0];
                  final maxVal = points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
                  if (maxVal == 0) return List.filled(points.length, 0.0);
                  return points.map((p) => p.value / maxVal).toList();
                },
                loading: () => const [0.0],
                error: (_, _) => const [0.0],
              ),
              height: 30,
              lineColor: AppTheme.fitnessPrimary,
              fillGradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.fitnessPrimary.withValues(alpha: 0.3),
                  AppTheme.fitnessPrimary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
