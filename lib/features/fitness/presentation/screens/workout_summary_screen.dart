/// VitalSync — Workout Summary Screen.
///
/// Displays a summary after completing a workout session.
/// Shows duration, volume, sets, exercises, and new PRs.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vitalsync/core/l10n/app_localizations.dart';
import 'package:vitalsync/core/theme/app_theme.dart';
import 'package:vitalsync/features/fitness/presentation/providers/workout_provider.dart';
import 'package:vitalsync/presentation/widgets/glassmorphic_app_bar.dart';
import 'package:vitalsync/presentation/widgets/glassmorphic_card.dart';

class WorkoutSummaryScreen extends ConsumerStatefulWidget {
  const WorkoutSummaryScreen({required this.sessionId, super.key});

  final int sessionId;

  @override
  ConsumerState<WorkoutSummaryScreen> createState() =>
      _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends ConsumerState<WorkoutSummaryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final sessionAsync = ref.watch(
      workoutSessionByIdProvider(widget.sessionId),
    );

    // Get sets for this session to calculate total sets count
    final setsAsync = ref.watch(sessionSetsProvider(widget.sessionId));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassmorphicAppBar(
        title: l10n.workoutSummary,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.go('/fitness'),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              AppTheme.fitnessPrimary.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: sessionAsync.when(
            data: (session) {
              if (session == null) {
                return Center(child: Text(l10n.workoutNotFound));
              }

              final duration = session.endTime != null
                  ? session.endTime!.difference(session.startTime)
                  : Duration.zero;

              return FadeTransition(
                opacity: _fadeAnimation,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Celebration Header
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        children: [
                          const Icon(
                            Icons.emoji_events,
                            size: 64,
                            color: AppTheme.fitnessPrimary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.workoutComplete,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.greatJob,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Summary Stats Card
                    GlassmorphicCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _SummaryStatRow(
                              icon: Icons.timer_outlined,
                              label: l10n.duration,
                              value: _formatDuration(duration),
                            ),
                            const Divider(height: 24),
                            _SummaryStatRow(
                              icon: Icons.fitness_center,
                              label: l10n.totalVolume,
                              value:
                                  '${session.totalVolume.toStringAsFixed(0)} kg',
                            ),
                            const Divider(height: 24),
                            setsAsync.when(
                              data: (sets) => _SummaryStatRow(
                                icon: Icons.repeat,
                                label: l10n.totalSets,
                                value: sets.length.toString(),
                              ),
                              loading: () => _SummaryStatRow(
                                icon: Icons.repeat,
                                label: l10n.totalSets,
                                value: '...',
                              ),
                              error: (_, _) => _SummaryStatRow(
                                icon: Icons.repeat,
                                label: l10n.totalSets,
                                value: '0',
                              ),
                            ),
                            const Divider(height: 24),
                            setsAsync.when(
                              data: (sets) {
                                // Count unique exercises
                                final uniqueExercises = sets
                                    .map((s) => s.exerciseId)
                                    .toSet()
                                    .length;
                                return _SummaryStatRow(
                                  icon: Icons.format_list_numbered,
                                  label: l10n.exercises,
                                  value: uniqueExercises.toString(),
                                );
                              },
                              loading: () => _SummaryStatRow(
                                icon: Icons.format_list_numbered,
                                label: l10n.exercises,
                                value: '...',
                              ),
                              error: (_, _) => _SummaryStatRow(
                                icon: Icons.format_list_numbered,
                                label: l10n.exercises,
                                value: '0',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              final totalSets = setsAsync.when(
                                data: (sets) => sets.length,
                                loading: () => 0,
                                error: (_, _) => 0,
                              );
                              final dateStr = DateFormat.yMMMd().format(
                                session.startTime,
                              );
                              final text =
                                  '${session.name} — $dateStr\n'
                                  '${l10n.duration}: ${_formatDuration(duration)}\n'
                                  '${l10n.totalVolume}: ${session.totalVolume.toStringAsFixed(0)} kg\n'
                                  '${l10n.totalSets}: $totalSets\n\n'
                                  '${l10n.trackedWithVitalSynch}';
                              SharePlus.instance.share(ShareParams(text: text));
                            },
                            icon: const Icon(Icons.share),
                            label: Text(l10n.share),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => context.go('/fitness'),
                            icon: const Icon(Icons.check),
                            label: Text(l10n.done),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.fitnessPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text(AppLocalizations.of(context).errorGeneric(error)),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}

class _SummaryStatRow extends StatelessWidget {
  const _SummaryStatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 24, color: AppTheme.fitnessPrimary),
        const SizedBox(width: 16),
        Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
