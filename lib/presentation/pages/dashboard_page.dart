/// VitalSync — Dashboard Page.
///
/// Unified health and fitness dashboard.
library;

import 'package:flutter/material.dart';

/// Dashboard page widget.
///
/// Displays unified view of health and fitness data with insights.
/// Will be fully implemented
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 72), // Space for app bar
                    Text(
                      'Good morning! 👋',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 24),
                    _buildPlaceholderCard(
                      context,
                      'Activity Rings',
                      'Track your daily health and fitness goals',
                      Icons.donut_large_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildPlaceholderCard(
                      context,
                      'Insights',
                      'Smart recommendations based on your data',
                      Icons.lightbulb_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildPlaceholderCard(
                      context,
                      'Today\'s Medications',
                      'Track your medication schedule',
                      Icons.medication_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildPlaceholderCard(
                      context,
                      'Workout Streak',
                      'Keep up the great work!',
                      Icons.fitness_center_rounded,
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Dashboard will be implemented',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 40, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
