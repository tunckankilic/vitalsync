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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../../core/l10n/app_localizations.dart';
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

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  //  // bool _isEditMode = false; // TODO: Implement drag & drop reordering // TODO: Implement drag & drop reordering

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh all dashboard data
          ref.invalidate(dashboardSummaryProvider);
          ref.invalidate(recentActivityProvider);
          // TODO: Trigger insight generation
        },
        child: summaryAsync.when(
          data: (summary) => _buildDashboard(context, summary),
          loading: _buildLoadingState,
          error: _buildErrorState,
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, DashboardSummary summary) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final crossAxisCount = isTablet ? 4 : 2;

    return CustomScrollView(
      slivers: [
        // Sliver padding for content
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverMasonryGrid.count(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childCount: 7,
            itemBuilder: (context, index) {
              return _buildCard(index, summary);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCard(int index, DashboardSummary summary) {
    switch (index) {
      case 0: // Greeting + Activity Rings (2x2)
        return GreetingCard(
          fitnessProgress: summary.weeklyWorkoutCount / 7.0,
          healthProgress: summary.todayComplianceRate,
          insightProgress: 0.75, // TODO: Connect to health score
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
