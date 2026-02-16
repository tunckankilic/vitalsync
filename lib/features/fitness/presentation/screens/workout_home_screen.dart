/// VitalSync — Workout Home Screen
///
/// Main fitness hub with start workout button, recent workouts,
/// templates grid, and quick stats.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitalsync/core/l10n/app_localizations.dart';
import '../../../../presentation/widgets/fitness/glassmorphic_card.dart';
import '../../../../presentation/widgets/fitness/sparkline_chart.dart';
import '../providers/progress_provider.dart';
import '../providers/workout_provider.dart';

/// Main workout home screen.
class WorkoutHomeScreen extends ConsumerWidget {
  /// Creates a workout home screen.
  const WorkoutHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final templates = ref.watch(workoutTemplatesProvider);
    final recentWorkouts = ref.watch(recentWorkoutsProvider);
    final weeklyStats = ref.watch(weeklyStatsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.workoutHome), centerTitle: false),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(workoutTemplatesProvider);
          ref.invalidate(recentWorkoutsProvider);
          ref.invalidate(weeklyStatsProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick Stats Card
              weeklyStats.when(
                data: (stats) => _QuickStatsCard(
                  weeklyVolume: stats.totalVolume,
                  weeklyWorkouts: stats.workoutCount,
                  volumeChange: stats.volumeChangePercent,
                ),
                loading: () => const _QuickStatsCardSkeleton(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),

              // Start Workout Hero Button
              _StartWorkoutButton(
                onTap: () => _handleStartWorkout(context, ref),
              ).animate().scale(
                duration: const Duration(milliseconds: 300),
                curve: Curves.elasticOut,
              ),
              const SizedBox(height: 32),

              // Recent Workouts
              Text(
                l10n.recentWorkouts,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              recentWorkouts.when(
                data: (workouts) {
                  if (workouts.isEmpty) {
                    return _EmptyState(
                      message: l10n.noWorkoutsYet,
                      subtitle: l10n.startYourFirstWorkout,
                    );
                  }
                  return SizedBox(
                    height: 160,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: workouts.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final workout = workouts[index];
                        return _RecentWorkoutCard(workout: workout);
                      },
                    ),
                  );
                },
                loading: () => const _RecentWorkoutsSkeletonList(),
                error: (_, _) => _EmptyState(
                  message: l10n.errorLoadingDashboard,
                  subtitle: l10n.retry,
                ),
              ),
              const SizedBox(height: 32),

              // Workout Templates
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.workoutTemplates,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _navigateToTemplates(context),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.createNewTemplate),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              templates.when(
                data: (templateList) {
                  if (templateList.isEmpty) {
                    return _EmptyState(
                      message: l10n.noTemplatesYet,
                      subtitle: l10n.createYourFirstTemplate,
                    );
                  }
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.2,
                        ),
                    itemCount: templateList.length + 1,
                    itemBuilder: (context, index) {
                      if (index == templateList.length) {
                        return _CreateTemplateCard(
                          onTap: () => _navigateToTemplates(context),
                        );
                      }
                      final template = templateList[index];
                      return _TemplateCard(
                        template: template,
                        onTap: () =>
                            _handleTemplateSelected(context, ref, template),
                        onLongPress: () =>
                            _showTemplateContextMenu(context, template),
                      );
                    },
                  );
                },
                loading: () => const _TemplatesGridSkeleton(),
                error: (_, _) => _EmptyState(
                  message: l10n.errorLoadingDashboard,
                  subtitle: l10n.retry,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleStartWorkout(BuildContext context, WidgetRef ref) {
    // Navigate to active workout screen
    // Implementation depends on router setup
    Navigator.pushNamed(context, '/fitness/active');
  }

  void _handleTemplateSelected(
    BuildContext context,
    WidgetRef ref,
    dynamic template,
  ) {
    // Start workout from template
    Navigator.pushNamed(
      context,
      '/fitness/active',
      arguments: {'templateId': template.id},
    );
  }

  void _navigateToTemplates(BuildContext context) {
    Navigator.pushNamed(context, '/fitness/templates');
  }

  void _showTemplateContextMenu(BuildContext context, dynamic template) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _TemplateContextMenu(template: template),
    );
  }
}

/// Start Workout hero button with gradient and pulse animation.
class _StartWorkoutButton extends StatelessWidget {
  const _StartWorkoutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child:
            Container(
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fitness_center,
                          size: 32,
                          color: theme.colorScheme.onPrimary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          l10n.startWorkout,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .animate(onPlay: (controller) => controller.repeat())
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.02, 1.02),
                  duration: const Duration(seconds: 2),
                  curve: Curves.easeInOut,
                )
                .then()
                .scale(
                  begin: const Offset(1.02, 1.02),
                  end: const Offset(1, 1),
                  duration: const Duration(seconds: 2),
                  curve: Curves.easeInOut,
                ),
      ),
    );
  }
}

/// Quick stats card showing weekly volume and workout count.
class _QuickStatsCard extends StatelessWidget {
  const _QuickStatsCard({
    required this.weeklyVolume,
    required this.weeklyWorkouts,
    required this.volumeChange,
  });

  final double weeklyVolume;
  final int weeklyWorkouts;
  final double volumeChange;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return GlassmorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.quickStats,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: l10n.thisWeeksVolume,
                  value: '${weeklyVolume.toStringAsFixed(0)} ${l10n.kg}',
                  change: volumeChange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatItem(
                  label: l10n.thisWeeksWorkouts,
                  value: weeklyWorkouts.toString(),
                  change: null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value, this.change});

  final String label;
  final String value;
  final double? change;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (change != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                change! > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: change! > 0 ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                '${change!.abs().toStringAsFixed(0)}% ${l10n.vsLastWeek}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: change! > 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Recent workout card with sparkline.
class _RecentWorkoutCard extends StatelessWidget {
  const _RecentWorkoutCard({required this.workout});

  final dynamic workout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // Mock sparkline data - in real implementation, get from workout sets
    final sparklineData = [100.0, 120.0, 110.0, 130.0, 125.0];

    return GlassmorphicCard(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              workout.name ?? 'Workout',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${workout.totalVolume?.toStringAsFixed(0) ?? 0} ${l10n.kg}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            SparklineChart(
              data: sparklineData,
              color: theme.colorScheme.primary,
            ),
            const Spacer(),
            Text(
              _formatDate(workout.startedAt, l10n),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date, AppLocalizations l10n) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) return l10n.today;
    if (difference.inDays == 1) return l10n.yesterday;
    return l10n.daysAgo(difference.inDays);
  }
}

/// Template card with exercise count and duration.
class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.onTap,
    required this.onLongPress,
  });

  final dynamic template;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: GlassmorphicCardWithStrip(
        stripColor: Color(template.color ?? 0xFF6200EE),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              template.name ?? 'Template',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              '${template.exerciseCount ?? 0} ${l10n.exercises}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              '~${template.estimatedDuration ?? 0} ${l10n.min}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Create template card.
class _CreateTemplateCard extends StatelessWidget {
  const _CreateTemplateCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return GestureDetector(
      onTap: onTap,
      child: GlassmorphicCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.createNewTemplate,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state widget.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, required this.subtitle});

  final String message;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Template context menu bottom sheet.
class _TemplateContextMenu extends StatelessWidget {
  const _TemplateContextMenu({required this.template});

  final dynamic template;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: Text(l10n.editTemplate),
            onTap: () {
              Navigator.pop(context);
              // Navigate to edit template
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: Text(l10n.deleteTemplate),
            onTap: () {
              Navigator.pop(context);
              // Show delete confirmation
            },
          ),
        ],
      ),
    );
  }
}

// Skeleton loaders
class _QuickStatsCardSkeleton extends StatelessWidget {
  const _QuickStatsCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const GlassmorphicCard(child: SizedBox(height: 100));
  }
}

class _RecentWorkoutsSkeletonList extends StatelessWidget {
  const _RecentWorkoutsSkeletonList();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, _) =>
            const GlassmorphicCard(child: SizedBox(width: 200)),
      ),
    );
  }
}

class _TemplatesGridSkeleton extends StatelessWidget {
  const _TemplatesGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: 4,
      itemBuilder: (_, _) => const GlassmorphicCard(child: SizedBox()),
    );
  }
}
