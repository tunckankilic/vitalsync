/// VitalSync — Activity Feed Card Widget.
///
/// Recent activity timeline (2x1):
/// - Unified timeline from recentActivityProvider
/// - Type-based icons (medication, workout, symptom)
/// - Chronological list, last 5 items
/// - Relative timestamps
/// - "View All" link
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/extensions.dart';

import '../../../presentation/providers/dashboard_provider.dart';
import '../glassmorphic_card.dart';

/// Activity feed card (2x1 grid size).
///
/// Features:
/// - Unified timeline of activities
/// - Type-specific icons and colors
/// - Relative timestamps
/// - View all link
class ActivityFeedCard extends ConsumerWidget {
  const ActivityFeedCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final activitiesAsync = ref.watch(recentActivityProvider);

    return GlassmorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.recentActivity,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/activity'),
                child: Text(l10n.viewAll),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Activity list
          Expanded(
            child: activitiesAsync.when(
              data: (activities) {
                if (activities.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.noRecentActivity,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: activities.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    return _ActivityItem(activity: activity);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({required this.activity});

  final ActivityItem activity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // Icon
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getColorForType(activity.type).withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              activity.icon ?? _getIconForType(activity.type),
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                activity.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // Timestamp
        Text(
          activity.timestamp.formatRelative(context),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Color _getColorForType(ActivityType type) {
    switch (type) {
      case ActivityType.medication:
        return Colors.green;
      case ActivityType.workout:
        return Colors.orange;
      case ActivityType.symptom:
        return Colors.red;
    }
  }

  String _getIconForType(ActivityType type) {
    switch (type) {
      case ActivityType.medication:
        return '💊';
      case ActivityType.workout:
        return '🏋️';
      case ActivityType.symptom:
        return '🤒';
    }
  }
}
