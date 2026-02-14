/// VitalSync — Medications Mini Card Widget.
///
/// Today's medications mini widget (1x1):
/// - Circular progress ring showing "3/5"
/// - Next medication time with countdown
/// - Relative time format
/// - Tap navigation to Health tab
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../presentation/providers/dashboard_provider.dart';
import '../glassmorphic_card.dart';

/// Medications mini card (1x1 grid size).
///
/// Features:
/// - Circular progress indicator
/// - Medication count (taken/total)
/// - Next medication time with relative countdown
/// - Tap to navigate to Health tab
class MedicationsMiniCard extends ConsumerWidget {
  const MedicationsMiniCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return GlassmorphicCard(
      child: summaryAsync.when(
        data: (summary) {
          final nextTime = summary.nextMedicationTime;
          final relativeTime = nextTime != null
              ? _formatRelativeTime(nextTime, l10n)
              : l10n.noUpcomingMedications;

          return InkWell(
            onTap: () => context.go('/health'),
            borderRadius: BorderRadius.circular(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Circular progress ring
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: summary.todayComplianceRate,
                        strokeWidth: 8,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.healthPrimary,
                        ),
                      ),
                      Text(
                        '${(summary.todayComplianceRate * 100).toInt()}%',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.healthPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Label
                Text(
                  l10n.todaysMedications,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                // Next medication time
                Text(
                  relativeTime,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Icon(Icons.error_outline, color: theme.colorScheme.error),
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime time, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = time.difference(now);

    if (difference.isNegative) {
      return l10n.noUpcomingMedications;
    }

    final hours = difference.inHours;
    final minutes = difference.inMinutes.remainder(60);

    if (hours > 0) {
      return 'Next in $hours${l10n.hoursShort} $minutes${l10n.minutesShort}';
    } else {
      return 'Next in $minutes${l10n.minutesShort}';
    }
  }
}
