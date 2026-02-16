/// VitalSync — Progress Screen.
///
/// Displays fitness progress with charts and statistics.
/// Shows volume trends, workout frequency, exercise progress, and PRs.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:vitalsync/core/l10n/app_localizations.dart';
import 'package:vitalsync/core/theme/app_theme.dart';
import 'package:vitalsync/features/fitness/presentation/providers/progress_provider.dart';
import 'package:vitalsync/presentation/widgets/glassmorphic_app_bar.dart';
import 'package:vitalsync/presentation/widgets/glassmorphic_card.dart';

/// Time range for progress data (UI-side enum with labels)
enum ProgressTimeRange {
  oneWeek('1W', 7),
  oneMonth('1M', 30),
  threeMonths('3M', 90),
  sixMonths('6M', 180),
  oneYear('1Y', 365);

  const ProgressTimeRange(this.label, this.days);
  final String label;
  final int days;

  TimeRange toProviderTimeRange() {
    switch (this) {
      case ProgressTimeRange.oneWeek:
        return TimeRange.oneWeek;
      case ProgressTimeRange.oneMonth:
        return TimeRange.oneMonth;
      case ProgressTimeRange.threeMonths:
        return TimeRange.threeMonths;
      case ProgressTimeRange.sixMonths:
        return TimeRange.sixMonths;
      case ProgressTimeRange.oneYear:
        return TimeRange.oneYear;
    }
  }
}

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  ProgressTimeRange _selectedRange = ProgressTimeRange.oneMonth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassmorphicAppBar(title: l10n.progress),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              AppTheme.fitnessPrimary.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Time Range Selector
              _TimeRangeSelector(
                selectedRange: _selectedRange,
                onRangeChanged: (range) {
                  setState(() => _selectedRange = range);
                },
              ),

              const SizedBox(height: 24),

              // Stats Summary
              _StatsSummaryCard(
                timeRange: _selectedRange.toProviderTimeRange(),
              ),

              const SizedBox(height: 16),

              // Volume Chart
              _VolumeChartCard(timeRange: _selectedRange.toProviderTimeRange()),

              const SizedBox(height: 16),

              // Workout Frequency Chart
              _WorkoutFrequencyCard(
                timeRange: _selectedRange.toProviderTimeRange(),
              ),

              const SizedBox(height: 16),

              // Personal Records Section
              _PersonalRecordsSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeRangeSelector extends StatelessWidget {
  const _TimeRangeSelector({
    required this.selectedRange,
    required this.onRangeChanged,
  });

  final ProgressTimeRange selectedRange;
  final ValueChanged<ProgressTimeRange> onRangeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ProgressTimeRange.values.map((range) {
          final isSelected = range == selectedRange;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(range.label),
              selected: isSelected,
              onSelected: (_) => onRangeChanged(range),
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              selectedColor: AppTheme.fitnessPrimary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatsSummaryCard extends ConsumerWidget {
  const _StatsSummaryCard({required this.timeRange});

  final TimeRange timeRange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final statsAsync = ref.watch(progressStatsProvider(timeRange));

    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.summary,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            statsAsync.when(
              data: (stats) => Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatItem(
                          icon: Icons.fitness_center,
                          label: l10n.totalWorkouts,
                          value: stats.workoutCount.toString(),
                        ),
                      ),
                      Expanded(
                        child: _StatItem(
                          icon: Icons.trending_up,
                          label: l10n.totalVolume,
                          value: '${stats.totalVolume.toStringAsFixed(0)} kg',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatItem(
                          icon: Icons.timer,
                          label: l10n.avgDuration,
                          value: stats.workoutCount > 0
                              ? '${(stats.totalDuration / stats.workoutCount).round()} min'
                              : '-',
                        ),
                      ),
                      Expanded(
                        child: _StatItem(
                          icon: Icons.emoji_events,
                          label: l10n.prsAchieved,
                          value: '-',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              loading: () => const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => Row(
                children: [
                  Expanded(
                    child: _StatItem(
                      icon: Icons.fitness_center,
                      label: l10n.totalWorkouts,
                      value: '-',
                    ),
                  ),
                  Expanded(
                    child: _StatItem(
                      icon: Icons.trending_up,
                      label: l10n.totalVolume,
                      value: '-',
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

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.fitnessPrimary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _VolumeChartCard extends ConsumerWidget {
  const _VolumeChartCard({required this.timeRange});

  final TimeRange timeRange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final chartDataAsync = ref.watch(volumeChartDataProvider(timeRange));

    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.fitness_center,
                  color: AppTheme.fitnessPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.volumeChart,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            chartDataAsync.when(
              data: (data) {
                if (data.isEmpty) {
                  return Container(
                    height: 200,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l10n.chartComingSoon,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  );
                }

                return SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY:
                          data
                              .map((d) => d.value)
                              .reduce((a, b) => a > b ? a : b) *
                          1.2,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final item = data[groupIndex];
                            return BarTooltipItem(
                              '${item.value.toStringAsFixed(0)} kg\n${DateFormat.MMMd().format(item.date)}',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < data.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    DateFormat.Md().format(data[index].date),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 10,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: null,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.1,
                            ),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      barGroups: data.asMap().entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.value,
                              color: AppTheme.fitnessPrimary,
                              width: data.length > 14 ? 6 : 12,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
              loading: () => Container(
                height: 200,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              ),
              error: (_, _) => Container(
                height: 200,
                alignment: Alignment.center,
                child: Text(
                  l10n.chartComingSoon,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutFrequencyCard extends ConsumerWidget {
  const _WorkoutFrequencyCard({required this.timeRange});

  final TimeRange timeRange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final frequencyAsync = ref.watch(workoutFrequencyProvider(timeRange));

    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: AppTheme.fitnessPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.workoutFrequency,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            frequencyAsync.when(
              data: (data) {
                if (data.isEmpty) {
                  return Container(
                    height: 200,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l10n.chartComingSoon,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  );
                }

                return SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY:
                          data
                              .map((d) => d.value)
                              .reduce((a, b) => a > b ? a : b) *
                          1.3,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final item = data[groupIndex];
                            return BarTooltipItem(
                              '${item.value.toInt()} workouts\n${DateFormat.MMMd().format(item.date)}',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < data.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    DateFormat.Md().format(data[index].date),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 10,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              if (value == value.roundToDouble()) {
                                return Text(
                                  '${value.toInt()}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 10,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.1,
                            ),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      barGroups: data.asMap().entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.value,
                              color: AppTheme.fitnessSecondary,
                              width: data.length > 14 ? 6 : 12,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
              loading: () => Container(
                height: 200,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              ),
              error: (_, _) => Container(
                height: 200,
                alignment: Alignment.center,
                child: Text(
                  l10n.chartComingSoon,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonalRecordsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events, color: AppTheme.fitnessPrimary),
                const SizedBox(width: 8),
                Text(
                  l10n.personalRecords,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Empty state placeholder
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 48,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.noPRsYet,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
