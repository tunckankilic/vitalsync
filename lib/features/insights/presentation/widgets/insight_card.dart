/// VitalSync — Insight Card Widget.
///
/// Reusable insight card for list and carousel views.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/enums/insight_priority.dart';
import '../../../../core/enums/insight_type.dart';
import '../../../../domain/entities/insights/insight.dart';
import '../../../../presentation/widgets/glassmorphic_card.dart';

/// Reusable insight card widget.
///
/// Features:
/// - Glassmorphic container
/// - Icon based on insight type
/// - Title and message preview
/// - Priority badge
/// - Timestamp
/// - Hero tag for shared element transition
class InsightCard extends StatelessWidget {
  const InsightCard({
    required this.insight,
    this.onTap,
    this.showFullMessage = false,
    super.key,
  });

  final Insight insight;
  final VoidCallback? onTap;
  final bool showFullMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Hero(
      tag: 'insight_${insight.id}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: GlassmorphicCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Icon based on insight type
                      _buildInsightIcon(insight.type, colorScheme),
                      const SizedBox(width: 12),
                      // Title
                      Expanded(
                        child: Text(
                          insight.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Priority badge
                      _buildPriorityBadge(insight.priority, theme),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Message
                  Text(
                    insight.message,
                    style: theme.textTheme.bodyMedium,
                    maxLines: showFullMessage ? null : 3,
                    overflow: showFullMessage ? null : TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Timestamp
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTimestamp(insight.generatedAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInsightIcon(InsightType type, ColorScheme colorScheme) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case InsightType.correlation:
        iconData = Icons.link;
        iconColor = Colors.blue;
      case InsightType.trend:
        iconData = Icons.trending_up;
        iconColor = Colors.green;
      case InsightType.anomaly:
        iconData = Icons.warning;
        iconColor = Colors.orange;
      case InsightType.suggestion:
        iconData = Icons.lightbulb;
        iconColor = Colors.amber;
      case InsightType.milestone:
        iconData = Icons.emoji_events;
        iconColor = Colors.purple;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: iconColor, size: 20),
    );
  }

  Widget _buildPriorityBadge(InsightPriority priority, ThemeData theme) {
    Color badgeColor;
    String label;

    switch (priority) {
      case InsightPriority.low:
        badgeColor = Colors.grey;
        label = 'Low';
      case InsightPriority.medium:
        badgeColor = Colors.orange;
        label = 'Medium';
      case InsightPriority.high:
        badgeColor = Colors.red;
        label = 'High';
      case InsightPriority.critical:
        badgeColor = Colors.red[900]!;
        label = 'Critical';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return DateFormat('MMM d').format(timestamp);
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
