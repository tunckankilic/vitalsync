/// VitalSync — Dashboard Page.
///
/// Unified health and fitness dashboard showing real data aggregated from the
/// registered repositories via [dashboardSummaryProvider].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../domain/entities/health/medication.dart';
import '../../domain/entities/insights/insight.dart';
import '../../features/dashboard/presentation/providers/dashboard_provider.dart';

/// Dashboard page widget.
///
/// Displays a unified view of today's medications, workout stats, streak,
/// a simple health score and the latest insight.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.refresh(dashboardSummaryProvider.future),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 72), // Space for app bar
                      Text(
                        '${l10n.goodMorning}! 👋',
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 24),
                      summaryAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.only(top: 64),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (error, _) => _DashboardError(error: error),
                        data: (summary) => _DashboardContent(summary: summary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders the populated dashboard from a loaded [DashboardSummary].
class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final latestInsight = summary.latestInsight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HealthScoreCard(percent: summary.healthPercent),
        const SizedBox(height: 16),
        _StatsRow(
          currentStreak: summary.currentStreak,
          totalWorkouts: summary.totalWorkouts,
          weeklyWorkouts: summary.weeklyWorkouts,
        ),
        const SizedBox(height: 16),
        _TodayMedicationsCard(
          medications: summary.todayMedications,
          takenToday: summary.takenToday,
        ),
        if (latestInsight != null) ...[
          const SizedBox(height: 16),
          _LatestInsightCard(insight: latestInsight),
        ],
      ],
    );
  }
}

/// Simple health score derived from medication compliance.
class _HealthScoreCard extends StatelessWidget {
  const _HealthScoreCard({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.donut_large_rounded,
              size: 40,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.healthScore, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: percent / 100,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.healthScoreCaption(percent),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Streak / total workouts / weekly workouts.
class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.currentStreak,
    required this.totalWorkouts,
    required this.weeklyWorkouts,
  });

  final int currentStreak;
  final int totalWorkouts;
  final int weeklyWorkouts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.local_fire_department_rounded,
            value: '$currentStreak',
            label: l10n.dayStreak,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            icon: Icons.fitness_center_rounded,
            value: '$totalWorkouts',
            label: l10n.workouts,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            icon: Icons.calendar_today_rounded,
            value: '$weeklyWorkouts',
            label: l10n.thisWeek,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(value, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Today's active medications with a taken/total summary.
class _TodayMedicationsCard extends StatelessWidget {
  const _TodayMedicationsCard({
    required this.medications,
    required this.takenToday,
  });

  final List<Medication> medications;
  final int takenToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.medication_rounded,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.todayMedications,
                  style: theme.textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  l10n.dosesTakenRatio(takenToday, medications.length),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (medications.isEmpty) ...[
              const SizedBox(height: 12),
              Text(
                l10n.noMedicationsToday,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ] else
              ...medications.map(
                (med) => Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 12,
                        color: Color(med.color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(med.name, style: theme.textTheme.bodyLarge),
                      ),
                      Text(
                        med.dosage,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The most recent active insight.
class _LatestInsightCard extends StatelessWidget {
  const _LatestInsightCard({required this.insight});

  final Insight insight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.lightbulb_rounded,
              size: 40,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(insight.title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    insight.message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline error state for the dashboard.
class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: theme.colorScheme.error),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.dashboardLoadError,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.pullToRetry,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
