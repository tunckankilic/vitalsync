/// VitalSync — Insight Carousel Card Widget.
///
/// Horizontal scrolling insight cards (2x1):
/// - PageView with max 3 active insights
/// - Gradient backgrounds based on insight type
/// - Shimmer effect for cross-module insights
/// - Dot indicator, long press to dismiss
/// - Empty state with CTAs
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/enums/insight_category.dart';
import '../../../core/enums/insight_type.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/insights/insight.dart';
import '../../../features/insights/presentation/providers/insight_provider.dart';
import '../glassmorphic_card.dart';

/// Insight carousel card (2x1 grid size).
///
/// Features:
/// - Horizontal PageView for up to 3 insights
/// - Gradient backgrounds by insight type
/// - Shimmer for cross-module insights
/// - Long press to dismiss
/// - Tap for detail navigation
/// - Empty state with CTAs
class InsightCarouselCard extends ConsumerStatefulWidget {
  const InsightCarouselCard({super.key});

  @override
  ConsumerState<InsightCarouselCard> createState() =>
      _InsightCarouselCardState();
}

class _InsightCarouselCardState extends ConsumerState<InsightCarouselCard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final insightsAsync = ref.watch(activeInsightsProvider);

    return GlassmorphicCard(
      padding: EdgeInsets.zero,
      child: insightsAsync.when(
        data: (insights) {
          if (insights.isEmpty) {
            return _buildEmptyState(context, l10n, theme);
          }

          final displayInsights = insights.take(3).toList();

          return Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: displayInsights.length,
                  itemBuilder: (context, index) {
                    return _buildInsightCard(context, displayInsights[index]);
                  },
                ),
              ),
              // Dot indicator
              if (displayInsights.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      displayInsights.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.3,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _buildEmptyState(context, l10n, theme),
      ),
    );
  }

  Widget _buildInsightCard(BuildContext context, Insight insight) {
    final theme = Theme.of(context);
    final gradient = _getGradientForInsight(insight);

    return GestureDetector(
      onTap: () {
        // Navigate to insight detail with Hero animation
        context.push('/insights/${insight.id}');
      },
      onLongPress: () {
        _showDismissDialog(context, insight);
      },
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          // Shimmer border for cross-module insights
          border: insight.category == InsightCategory.crossModule
              ? Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Icon(
              _getIconForInsightType(insight.type),
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 12),
            // Title
            Text(
              insight.title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // Message
            Text(
              insight.message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.dataCollecting,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _ctaChip(context, l10n.startFirstWorkout, Icons.fitness_center),
                _ctaChip(context, l10n.addFirstMedication, Icons.medication),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _ctaChip(BuildContext context, String label, IconData icon) {
    final theme = Theme.of(context);
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () {
        // Navigate based on action
        if (label.contains('Workout')) {
          context.go('/fitness');
        } else {
          context.go('/health');
        }
      },
      backgroundColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(color: theme.colorScheme.onPrimaryContainer),
    );
  }

  void _showDismissDialog(BuildContext context, Insight insight) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.dismissInsightTitle),
        content: Text(l10n.dismissInsightMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              // TODO: Add dismiss functionality when insight notifier is implemented
              // ref.read(insightNotifierProvider.notifier).dismiss(insight.id);
              Navigator.pop(context);
            },
            child: Text(l10n.dismiss),
          ),
        ],
      ),
    );
  }

  LinearGradient _getGradientForInsight(Insight insight) {
    switch (insight.category) {
      case InsightCategory.health:
        return AppTheme.healthGradient;
      case InsightCategory.fitness:
        return AppTheme.fitnessGradient;
      case InsightCategory.crossModule:
        return AppTheme.insightGradient;
    }
  }

  IconData _getIconForInsightType(InsightType type) {
    switch (type) {
      case InsightType.correlation:
        return Icons.analytics_outlined;
      case InsightType.trend:
        return Icons.trending_up;
      case InsightType.anomaly:
        return Icons.warning_amber_outlined;
      case InsightType.suggestion:
        return Icons.tips_and_updates_outlined;
      case InsightType.milestone:
        return Icons.emoji_events_outlined;
    }
  }
}
