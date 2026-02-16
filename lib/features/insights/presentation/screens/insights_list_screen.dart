/// VitalSync — Insights List Screen.
///
/// Filterable list of insights with swipe-to-dismiss functionality.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/enums/insight_category.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../providers/insight_provider.dart';
import '../widgets/insight_card.dart';

/// Insights list screen with filtering and tabs.
///
/// Features:
/// - Filter chips (All/Health/Fitness/Cross-Module)
/// - Tabs (Active/Dismissed)
/// - Swipe-to-dismiss
/// - Shared element transitions to detail
/// - Empty state with progress indicator
class InsightsListScreen extends ConsumerStatefulWidget {
  const InsightsListScreen({super.key});

  @override
  ConsumerState<InsightsListScreen> createState() => _InsightsListScreenState();
}

class _InsightsListScreenState extends ConsumerState<InsightsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  InsightCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.insights),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.active),
            Tab(text: l10n.dismissed),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip(
                  label: l10n.all,
                  isSelected: _selectedCategory == null,
                  onTap: () => setState(() => _selectedCategory = null),
                  theme: theme,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: l10n.health,
                  isSelected: _selectedCategory == InsightCategory.health,
                  onTap: () => setState(
                    () => _selectedCategory = InsightCategory.health,
                  ),
                  theme: theme,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: l10n.fitness,
                  isSelected: _selectedCategory == InsightCategory.fitness,
                  onTap: () => setState(
                    () => _selectedCategory = InsightCategory.fitness,
                  ),
                  theme: theme,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: l10n.overallWellness,
                  isSelected: _selectedCategory == InsightCategory.crossModule,
                  onTap: () => setState(
                    () => _selectedCategory = InsightCategory.crossModule,
                  ),
                  theme: theme,
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildActiveInsightsList(),
                _buildDismissedInsightsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isSelected
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveInsightsList() {
    final l10n = AppLocalizations.of(context);
    final activeInsightsAsync = ref.watch(activeInsightsProvider);

    return activeInsightsAsync.when(
      data: (insights) {
        // Filter by category if selected
        final filteredInsights = _selectedCategory == null
            ? insights
            : insights
                  .where((insight) => insight.category == _selectedCategory)
                  .toList();

        if (filteredInsights.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredInsights.length,
          itemBuilder: (context, index) {
            final insight = filteredInsights[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Dismissible(
                key: Key('insight_${insight.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.dismissInsightTitle),
                      content: Text(l10n.dismissInsightMessage),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(l10n.cancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(l10n.dismiss),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) {
                  ref.read(insightProvider.notifier).dismiss(insight.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.insightDismissed)),
                  );
                },
                child: InsightCard(
                  insight: insight,
                  onTap: () {
                    context.push('/insights/detail/${insight.id}');
                  },
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text(l10n.errorLoadingInsights(error))),
    );
  }

  Widget _buildDismissedInsightsList() {
    final l10n = AppLocalizations.of(context);
    final dismissedInsightsAsync = ref.watch(dismissedInsightsProvider);

    return dismissedInsightsAsync.when(
      data: (insights) {
        // Filter by category if selected
        final filteredInsights = _selectedCategory == null
            ? insights
            : insights
                  .where((insight) => insight.category == _selectedCategory)
                  .toList();

        if (filteredInsights.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                l10n.noDismissedInsights,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredInsights.length,
          itemBuilder: (context, index) {
            final insight = filteredInsights[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Opacity(
                opacity: 0.6,
                child: InsightCard(
                  insight: insight,
                  onTap: () {
                    context.push('/insights/detail/${insight.id}');
                  },
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text(l10n.errorLoadingDismissedInsights(error))),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 64,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noInsightsYet,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.insightsEmptyDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Progress indicator
            LinearProgressIndicator(
              value: 0.4, // TODO: Calculate actual progress
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.dataCollectedProgress(3, 7),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
