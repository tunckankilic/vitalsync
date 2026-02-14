/// VitalSync — Insight Detail Screen.
///
/// Full-page detail view for insights with interactive data visualizations.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/enums/insight_type.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../domain/entities/insights/insight.dart';
import '../../../../presentation/widgets/glassmorphic_card.dart';
import '../providers/insight_provider.dart';
import '../widgets/charts/anomaly_sparkline.dart';
import '../widgets/charts/correlation_chart.dart';
import '../widgets/charts/pattern_heatmap.dart';
import '../widgets/charts/radial_progress_chart.dart';
import '../widgets/charts/trend_chart.dart';

/// Insight detail screen with Hero transition and dynamic chart rendering.
///
/// Features:
/// - Hero transition from insight card
/// - Glassmorphic full-page card
/// - Dynamic chart based on insight type
/// - Action buttons with deep links
/// - Feedback mechanism (👍/👎)
/// - Dismiss functionality
class InsightDetailScreen extends ConsumerStatefulWidget {
  const InsightDetailScreen({required this.insightId, super.key});

  final int insightId;

  @override
  ConsumerState<InsightDetailScreen> createState() =>
      _InsightDetailScreenState();
}

class _InsightDetailScreenState extends ConsumerState<InsightDetailScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final activeInsightsAsync = ref.watch(activeInsightsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.insights),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: activeInsightsAsync.when(
        data: (insights) {
          final insight = insights.firstWhere(
            (i) => i.id == widget.insightId,
            orElse: () => throw Exception('Insight not found'),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Main insight card with Hero transition
                Hero(
                  tag: 'insight_${insight.id}',
                  child: Material(
                    color: Colors.transparent,
                    child: GlassmorphicCard(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon based on insight type
                            _buildInsightIcon(insight.type, colorScheme),
                            const SizedBox(height: 16),
                            // Title
                            Text(
                              insight.title,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Full message
                            Text(
                              insight.message,
                              style: theme.textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 16),
                            // Generated date and validity
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 16,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Valid until ${_formatDate(insight.validUntil)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.6,
                                    ),
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
                const SizedBox(height: 20),
                // Data visualization based on insight type
                _buildDataVisualization(insight, theme, colorScheme),
                const SizedBox(height: 20),
                // Action button (if applicable)
                if (insight.data.containsKey('action'))
                  _buildActionButton(
                    insight.data['action'] as String,
                    insight.data['actionLabel'] as String? ?? 'Take Action',
                    theme,
                  ),
                const SizedBox(height: 20),
                // Feedback section
                GlassmorphicCard(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Was this insight helpful?',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildFeedbackButton(
                              context,
                              icon: Icons.thumb_up,
                              label: 'Helpful',
                              isPositive: true,
                              onTap: () => _submitFeedback(insight, true),
                            ),
                            _buildFeedbackButton(
                              context,
                              icon: Icons.thumb_down,
                              label: 'Not Helpful',
                              isPositive: false,
                              onTap: () => _submitFeedback(insight, false),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Dismiss button
                OutlinedButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () => _dismissInsight(insight),
                  icon: const Icon(Icons.close),
                  label: const Text('Dismiss Insight'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Error loading insight: $error')),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(iconData, color: iconColor, size: 32),
    );
  }

  Widget _buildDataVisualization(
    Insight insight,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    switch (insight.type) {
      case InsightType.correlation:
        return _buildCorrelationChart(insight);
      case InsightType.trend:
        return _buildTrendChart(insight);
      case InsightType.anomaly:
        return _buildAnomalyChart(insight);
      case InsightType.milestone:
        return _buildMilestoneChart(insight);
      case InsightType.suggestion:
        // Check if this is a pattern-based suggestion
        if (insight.data.containsKey('patternData')) {
          return _buildPatternHeatmap(insight);
        }
        // Suggestions without pattern data don't have charts
        return const SizedBox.shrink();
    }
  }

  Widget _buildCorrelationChart(Insight insight) {
    final data = insight.data;
    return CorrelationChart(
      leftLabel: data['leftLabel'] as String? ?? 'Group A',
      leftValue: (data['leftValue'] as num?)?.toDouble() ?? 0,
      rightLabel: data['rightLabel'] as String? ?? 'Group B',
      rightValue: (data['rightValue'] as num?)?.toDouble() ?? 0,
    );
  }

  Widget _buildTrendChart(Insight insight) {
    final data = insight.data;
    final currentData =
        (data['currentData'] as List<dynamic>?)
            ?.map(
              (e) => TrendDataPoint(
                date: DateTime.parse(e['date'] as String),
                value: (e['value'] as num).toDouble(),
              ),
            )
            .toList() ??
        [];
    final previousData =
        (data['previousData'] as List<dynamic>?)
            ?.map(
              (e) => TrendDataPoint(
                date: DateTime.parse(e['date'] as String),
                value: (e['value'] as num).toDouble(),
              ),
            )
            .toList() ??
        [];

    return TrendChart(
      currentData: currentData,
      previousData: previousData,
      title: data['chartTitle'] as String?,
    );
  }

  Widget _buildAnomalyChart(Insight insight) {
    final data = insight.data;
    final sparklineData =
        (data['sparklineData'] as List<dynamic>?)
            ?.map(
              (e) => SparklineDataPoint(
                index: e['index'] as int,
                value: (e['value'] as num).toDouble(),
                isAnomaly: e['isAnomaly'] as bool? ?? false,
              ),
            )
            .toList() ??
        [];

    return AnomalySparkline(
      data: sparklineData,
      normalRangeMin: (data['normalRangeMin'] as num?)?.toDouble() ?? 0,
      normalRangeMax: (data['normalRangeMax'] as num?)?.toDouble() ?? 100,
    );
  }

  Widget _buildMilestoneChart(Insight insight) {
    final data = insight.data;
    return RadialProgressChart(
      progress: (data['progress'] as num?)?.toDouble() ?? 0,
      label: data['label'] as String? ?? 'Progress',
    );
  }

  Widget _buildPatternHeatmap(Insight insight) {
    final data = insight.data;
    final patternData = data['patternData'] as Map<String, dynamic>?;

    if (patternData == null) {
      return const SizedBox.shrink();
    }

    // Convert pattern data to heatmap format
    // Expected format: {"Monday": {"morning": 5, "afternoon": 2, ...}, ...}
    final heatmapData = <HeatmapCell>[];
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final timeSlots = ['Morning', 'Afternoon', 'Evening', 'Night'];

    for (var dayIndex = 0; dayIndex < days.length; dayIndex++) {
      final day = days[dayIndex];
      final dayData = patternData[day] as Map<String, dynamic>?;

      if (dayData != null) {
        for (var slotIndex = 0; slotIndex < timeSlots.length; slotIndex++) {
          final slot = timeSlots[slotIndex].toLowerCase();
          final count = (dayData[slot] as num?)?.toDouble() ?? 0;

          heatmapData.add(
            HeatmapCell(row: dayIndex, column: slotIndex, value: count),
          );
        }
      }
    }

    return PatternHeatmap(
      data: heatmapData,
      rowLabels: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      columnLabels: timeSlots,
    );
  }

  Widget _buildActionButton(String action, String label, ThemeData theme) {
    return ElevatedButton.icon(
      onPressed: () {
        // Handle deep link navigation based on action
        // Examples: /medications/edit/:id, /workouts/templates, etc.
        if (action.isNotEmpty) {
          context.push(action);
        }
      },
      icon: const Icon(Icons.arrow_forward),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _buildFeedbackButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isPositive,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isPositive ? Colors.green : Colors.red,
                size: 32,
              ),
              const SizedBox(height: 4),
              Text(label, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitFeedback(Insight insight, bool isHelpful) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final analytics = ref.read(analyticsServiceProvider);
      await analytics.logInsightFeedback(
        insightType: insight.type.toString(),
        helpful: isHelpful,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your feedback!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting feedback: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _dismissInsight(Insight insight) async {
    if (_isProcessing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dismiss Insight'),
        content: const Text('Are you sure you want to dismiss this insight?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);

    try {
      await ref.read(insightProvider.notifier).dismiss(insight.id);

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error dismissing insight: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays} days';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours';
    } else {
      return 'soon';
    }
  }
}
