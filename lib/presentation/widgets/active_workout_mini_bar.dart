/// VitalSync — Active Workout Mini-Bar Widget.
///
/// Floating mini-bar that appears when a workout is active,
/// showing elapsed time and providing quick navigation back to workout.
library;

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../features/fitness/presentation/providers/workout_provider.dart';

/// Active workout mini-bar widget.
///
/// Displays:
/// - Workout name
/// - Elapsed time (real-time updating)
/// - Tap to return to active workout screen
///
/// Styled with glassmorphic design matching app theme.
class ActiveWorkoutMiniBar extends ConsumerStatefulWidget {
  const ActiveWorkoutMiniBar({super.key});

  @override
  ConsumerState<ActiveWorkoutMiniBar> createState() =>
      _ActiveWorkoutMiniBarState();
}

class _ActiveWorkoutMiniBarState extends ConsumerState<ActiveWorkoutMiniBar> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    // Update elapsed time every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsed = _calculateElapsed();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Duration _calculateElapsed() {
    final activeSessionAsync = ref.read(activeSessionProvider);
    return activeSessionAsync.when(
      data: (session) {
        if (session == null) return Duration.zero;
        return DateTime.now().difference(session.startTime);
      },
      loading: () => _elapsed, // Keep previous value while loading
      error: (_, _) => Duration.zero,
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeSessionAsync = ref.watch(activeSessionProvider);

    return activeSessionAsync.when(
      data: (session) {
        if (session == null) {
          return const SizedBox.shrink();
        }

        // Update elapsed time based on session start time
        final elapsed = DateTime.now().difference(session.startTime);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: -5,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // Navigate to active workout screen
                      context.push('/fitness/active-workout');
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          // Workout icon
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.fitnessPrimary.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.fitness_center_rounded,
                              color: AppTheme.fitnessPrimary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Workout info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  session.name,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10n.timeElapsed,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Elapsed time
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.fitnessPrimary.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _formatDuration(elapsed),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppTheme.fitnessPrimary,
                                fontWeight: FontWeight.bold,
                                fontFeatures: [
                                  const FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Arrow icon
                          Icon(
                            Icons.chevron_right_rounded,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
