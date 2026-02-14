/// VitalSync — Greeting Card Widget.
///
/// Large 2x2 dashboard card featuring:
/// - Time-based greeting (morning/afternoon/evening) - localized
/// - User name from profile
/// - Activity Rings (animated, tap to navigate)
/// - Grid size: 2x2
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/l10n/app_localizations.dart';
import '../activity_rings.dart';
import '../glassmorphic_card.dart';

/// Large greeting card with Activity Rings (2x2 grid size).
///
/// Features:
/// - Time-based greeting (localized)
/// - User name display
/// - Activity Rings with three nested rings
/// - Tap to navigate to weekly report
class GreetingCard extends ConsumerWidget {
  const GreetingCard({
    required this.fitnessProgress,
    required this.healthProgress,
    required this.insightProgress,
    required this.centerMetric,
    required this.centerLabel,
    super.key,
  });

  final double fitnessProgress;
  final double healthProgress;
  final double insightProgress;
  final String centerMetric;
  final String centerLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final userAsync = ref.watch(currentUserProvider);

    // Get time-based greeting
    final greeting = _getGreeting(l10n);

    return GlassmorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting text
          userAsync.when(
            data: (user) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.name ?? '',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            loading: () => Text(
              greeting,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            error: (_, _) => Text(
              greeting,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const Spacer(),

          // Activity Rings
          Center(
            child: ActivityRings(
              fitnessProgress: fitnessProgress,
              healthProgress: healthProgress,
              insightProgress: insightProgress,
              centerMetric: centerMetric,
              centerLabel: centerLabel,
              size: 180,
              onTap: () {
                // Navigate to weekly report
                context.push('/insights/weekly-report');
              },
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }

  String _getGreeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return l10n.goodMorning;
    } else if (hour < 17) {
      return l10n.goodAfternoon;
    } else if (hour < 21) {
      return l10n.goodEvening;
    } else {
      return l10n.goodNight;
    }
  }
}
