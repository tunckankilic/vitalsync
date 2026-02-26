/// VitalSync — Dashboard Screen.
///
/// Unified dashboard with Bento Grid layout featuring:
/// - StaggeredGridView layout (2 columns phone, 4 columns tablet)
/// - Glassmorphic cards with 12px gaps
/// - Pull-to-refresh functionality
/// - Drag & drop reordering (long press)
/// - Loading/empty/error states
/// - Layout persistence via SharedPreferences
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../features/insights/presentation/providers/insight_engine_provider.dart';
import '../../../features/insights/presentation/providers/insight_provider.dart';
import '../../providers/dashboard_layout_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/dashboard/activity_feed_card.dart';
import '../../widgets/dashboard/greeting_card.dart';
import '../../widgets/dashboard/insight_carousel_card.dart';
import '../../widgets/dashboard/medications_mini_card.dart';
import '../../widgets/dashboard/quick_actions_card.dart';
import '../../widgets/dashboard/streak_workout_card.dart';
import '../../widgets/dashboard/weekly_chart_card.dart';

/// Main dashboard screen with Bento Grid layout.
///
/// Features:
/// - Bento Grid layout using StaggeredGridView
/// - Responsive grid (2 columns phone, 4 tablets)
/// - Pull-to-refresh
/// - Drag & drop reordering
/// - Shimmer loading states
/// - Empty and error states
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _isEditMode = false;
  late AnimationController _jiggleController;

  @override
  void initState() {
    super.initState();
    _jiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _jiggleController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (_isEditMode) {
        _jiggleController.repeat(reverse: true);
      } else {
        _jiggleController.stop();
        _jiggleController.reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardSummaryProvider);
          ref.invalidate(recentActivityProvider);

          try {
            final insightEngine = ref.read(insightEngineProvider);
            await insightEngine.generateAllInsights();
            ref.invalidate(activeInsightsProvider);
          } catch (e) {
            debugPrint('Failed to generate insights: $e');
          }
        },
        child: Column(
          children: [
            // Edit mode banner
            if (_isEditMode)
              MaterialBanner(
                content: Text(l10n.longPressToReorder),
                leading: const Icon(Icons.drag_indicator),
                actions: [
                  TextButton(
                    onPressed: _toggleEditMode,
                    child: Text(l10n.done),
                  ),
                ],
              ),
            Expanded(
              child: summaryAsync.when(
                data: (summary) => _isEditMode
                    ? _buildEditableDashboard(context, summary)
                    : _buildDashboard(context, summary),
                loading: _buildLoadingState,
                error: _buildErrorState,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, DashboardSummary summary) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final crossAxisCount = isTablet ? 4 : 2;
    final cardOrder = ref.watch(dashboardLayoutProvider);

    return GestureDetector(
      onLongPress: _toggleEditMode,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childCount: 7,
              itemBuilder: (context, index) {
                return _buildCard(cardOrder[index], summary);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableDashboard(
      BuildContext context, DashboardSummary summary) {
    final cardOrder = ref.watch(dashboardLayoutProvider);

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final scale =
                1.0 + Curves.easeInOut.transform(animation.value) * 0.03;
            return Transform.scale(
              scale: scale,
              child: Material(
                elevation: 8,
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                child: child,
              ),
            );
          },
          child: child,
        );
      },
      onReorder: (oldIndex, newIndex) {
        ref.read(dashboardLayoutProvider.notifier).reorder(oldIndex, newIndex);
      },
      itemCount: 7,
      itemBuilder: (context, index) {
        final cardIndex = cardOrder[index];
        return Padding(
          key: ValueKey('dashboard_card_$cardIndex'),
          padding: const EdgeInsets.only(bottom: 12),
          child: AnimatedBuilder(
            animation: _jiggleController,
            builder: (context, child) {
              final jiggle =
                  math.sin(_jiggleController.value * math.pi * 2) * 0.5;
              return Transform.rotate(
                angle: jiggle * math.pi / 180,
                child: child,
              );
            },
            child: _buildCard(cardIndex, summary),
          ),
        );
      },
    );
  }

  Widget _buildCard(int index, DashboardSummary summary) {
    switch (index) {
      case 0: // Greeting + Activity Rings (2x2)
        return GreetingCard(
          fitnessProgress: summary.weeklyWorkoutCount / 7.0,
          healthProgress: summary.todayComplianceRate,
          insightProgress:
              summary.healthScore / 100.0, // Health score 0-100 → 0-1
          centerMetric: '${summary.currentStreak}',
          centerLabel: 'day streak',
        );

      case 1: // Insight Carousel (2x1)
        return const InsightCarouselCard();

      case 2: // Medications Mini (1x1)
        return const MedicationsMiniCard();

      case 3: // Streak & Workout (1x1)
        return const StreakWorkoutCard();

      case 4: // Weekly Chart (2x1)
        return const WeeklyChartCard();

      case 5: // Quick Actions (2x1)
        return const QuickActionsCard();

      case 6: // Activity Feed (2x1)
        return const ActivityFeedCard();

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildLoadingState() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverMasonryGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childCount: 7,
            itemBuilder: (context, index) {
              return _buildShimmerCard(index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerCard(int index) {
    // Different heights for different card types
    final height = [280.0, 180.0, 200.0, 200.0, 220.0, 120.0, 250.0][index];

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildErrorState(Object error, StackTrace stackTrace) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              l10n.errorLoadingDashboard,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(dashboardSummaryProvider);
              },
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
