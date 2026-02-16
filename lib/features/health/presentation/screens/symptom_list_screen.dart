import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:vitalsync/core/l10n/app_localizations.dart';
import 'package:vitalsync/core/theme/app_theme.dart';
import 'package:vitalsync/core/utils/extensions.dart';
import 'package:vitalsync/domain/entities/health/symptom.dart';
import 'package:vitalsync/features/health/presentation/providers/symptom_provider.dart';
import 'package:vitalsync/presentation/widgets/glassmorphic_card.dart';

class SymptomListScreen extends ConsumerStatefulWidget {
  const SymptomListScreen({super.key});

  @override
  ConsumerState<SymptomListScreen> createState() => _SymptomListScreenState();
}

class _SymptomListScreenState extends ConsumerState<SymptomListScreen> {
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // Fetch symptoms for date range
    final symptomsAsync = ref.watch(
      symptomsInDateRangeProvider(
        startDate: _dateRange.start,
        endDate: _dateRange.end,
      ),
    );

    // Calculate chart data (frequency)
    // We can use the separate provider `symptomFrequencyProvider` but that might be for fixed days.
    // Let's compute local frequency for flexibility with custom date range.

    return Scaffold(
      extendBodyBehindAppBar: true,
      // AppBar handled by AppShell or we can add specific actions.
      // We'll add a header in the body.
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header & Filter
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        l10n.symptoms,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.date_range, size: 16),
                      label: Text(
                        '${_dateRange.start.format('MMM d')} - ${_dateRange.end.format('MMM d')}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () async {
                        final newRange = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          initialDateRange: _dateRange,
                        );
                        if (newRange != null) {
                          setState(() => _dateRange = newRange);
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: symptomsAsync.when(
                  data: (symptoms) {
                    if (symptoms.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.healing_rounded,
                              size: 48,
                              color: theme.disabledColor.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(l10n.noSymptomsLogged),
                          ],
                        ),
                      );
                    }

                    // Compute Frequency
                    final frequency = <String, int>{};
                    for (final s in symptoms) {
                      frequency[s.name] = (frequency[s.name] ?? 0) + 1;
                    }
                    // Sort by frequency
                    final sortedKeys = frequency.keys.toList()
                      ..sort((a, b) => frequency[b]!.compareTo(frequency[a]!));

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Frequency Chart
                        if (sortedKeys.isNotEmpty) ...[
                          Text(
                            l10n.mostFrequent,
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 120,
                            child: GlassmorphicCard(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  barTouchData: BarTouchData(
                                    touchTooltipData: BarTouchTooltipData(
                                      getTooltipColor: (_) =>
                                          theme.colorScheme.surface,
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          if (value.toInt() <
                                              sortedKeys.length) {
                                            final name =
                                                sortedKeys[value.toInt()];
                                            // Shorten name if too long
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4,
                                              ),
                                              child: Text(
                                                name.length > 5
                                                    ? '${name.substring(0, 4)}..'
                                                    : name,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                ),
                                              ),
                                            );
                                          }
                                          return const SizedBox();
                                        },
                                      ),
                                    ),
                                    leftTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  gridData: const FlGridData(show: false),
                                  borderData: FlBorderData(show: false),
                                  barGroups: List.generate(
                                    sortedKeys.take(5).length,
                                    (index) {
                                      final name = sortedKeys[index];
                                      final count = frequency[name]!;
                                      return BarChartGroupData(
                                        x: index,
                                        barRods: [
                                          BarChartRodData(
                                            toY: count.toDouble(),
                                            color: AppTheme.healthPrimary,
                                            width: 16,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Recent List
                        Text(
                          l10n.recentTimeline,
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        ...symptoms.map(
                          (symptom) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _SymptomCard(symptom: symptom),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text(AppLocalizations.of(context).errorGeneric(err))),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/health/add-symptom'),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.logSymptom),
        backgroundColor: AppTheme.healthPrimary,
      ),
    );
  }
}

class _SymptomCard extends StatelessWidget {
  const _SymptomCard({required this.symptom});

  final Symptom symptom;

  @override
  Widget build(BuildContext context) {
    return GlassmorphicCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _SeverityGauge(severity: symptom.severity),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  symptom.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  symptom.date.format('MMM d, yyyy'), // Relative or date format
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (symptom.notes != null && symptom.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    symptom.notes!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Theme.of(context).disabledColor),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded),
            onPressed: () {
              // Edit/Delete bottom sheet could go here
            },
          ),
        ],
      ),
    );
  }
}

class _SeverityGauge extends StatelessWidget {
  const _SeverityGauge({required this.severity});

  final int severity;

  @override
  Widget build(BuildContext context) {
    final color = _getColor(severity);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        severity.toString(),
        style: TextStyle(fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Color _getColor(int severity) {
    switch (severity) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.amber;
      case 4:
        return Colors.orange;
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
