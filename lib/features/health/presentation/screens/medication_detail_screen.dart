import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vitalsync/core/enums/medication_log_status.dart';
import 'package:vitalsync/core/l10n/app_localizations.dart';

import 'package:vitalsync/core/utils/extensions.dart';
import 'package:vitalsync/domain/entities/health/medication.dart';
import 'package:vitalsync/domain/entities/health/medication_log.dart';
import 'package:vitalsync/features/health/presentation/providers/medication_log_provider.dart';
import 'package:vitalsync/features/health/presentation/providers/medication_provider.dart';
import 'package:vitalsync/presentation/widgets/glassmorphic_app_bar.dart';
import 'package:vitalsync/presentation/widgets/glassmorphic_card.dart';

class MedicationDetailScreen extends ConsumerWidget {
  const MedicationDetailScreen({required this.medicationId, super.key});

  final int medicationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // In a real app, we'd use a provider to get medication by ID
    // For now, fetching from all medications and finding first
    final medicationsAsync = ref.watch(medicationsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassmorphicAppBar(
        title: l10n.medicationDetails,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => context.push(
              '/health/edit-medication?id=$medicationId',
              extra: {
                'id': medicationId,
              }, // Passing extra for easy retrieval if needed
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded),
            onPressed: () {
              // Delete confirmation dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.deleteMedication),
                  content: Text(l10n.deleteConfirmation),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.cancel),
                    ),
                    TextButton(
                      onPressed: () async {
                        await ref
                            .read(medicationProvider.notifier)
                            .deleteMedication(medicationId);
                        Navigator.pop(context); // Close dialog
                        context.pop(); // Go back to list
                      },
                      child: Text(
                        l10n.delete,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: medicationsAsync.when(
            data: (medications) {
              final matches = medications.where((m) => m.id == medicationId);
              if (matches.isEmpty) {
                // The medication was just deleted (the list updates reactively
                // before this screen finishes popping). Render nothing instead
                // of throwing "Medication not found".
                return const SizedBox.shrink();
              }
              return _MedicationDetailContent(medication: matches.first);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text(AppLocalizations.of(context).errorGeneric(err))),
          ),
        ),
      ),
    );
  }
}

class _MedicationDetailContent extends ConsumerWidget {
  const _MedicationDetailContent({required this.medication});

  final Medication medication;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // Logs for the compliance chart and the history list.
    //
    // The range is pinned to day boundaries on purpose. Passing DateTime.now()
    // straight into the family re-keyed the provider on every rebuild (each
    // call has a new microsecond value), so it re-entered the loading state
    // endlessly — the history and compliance sections were stuck on the
    // spinner. dateOnly keeps the key constant for the whole day; endDate is
    // tomorrow's midnight so today's logs are still included.
    final today = DateUtils.dateOnly(DateTime.now());
    final startDate = today.subtract(const Duration(days: 30));
    final endDate = today.add(const Duration(days: 1));

    final logsListAsync = ref.watch(
      logsInDateRangeProvider(startDate: startDate, endDate: endDate),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header Info
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(medication.color).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.medication_rounded,
                  size: 48,
                  color: Color(medication.color),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                medication.name,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${medication.dosage} • ${medication.frequency.displayName}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Compliance Chart
        Text(l10n.complianceHistory, style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: GlassmorphicCard(
            padding: const EdgeInsets.all(16),
            child: logsListAsync.when(
              data: (logs) => _ComplianceChart(
                logs: logs
                    .where((l) => l.medicationId == medication.id)
                    .toList(),
                periodDays: 30,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(child: Text(l10n.chartError)),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Log History List
        Text(l10n.history, style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        logsListAsync.when(
          data: (logs) {
            // Only this medication's logs — the range provider returns every
            // medication's logs, so the history must be filtered by id.
            final medLogs = logs
                .where((l) => l.medicationId == medication.id)
                .toList();
            if (medLogs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(l10n.noLogsYet, textAlign: TextAlign.center),
              );
            }
            // Sort by date desc
            final sortedLogs = medLogs
              ..sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));

            return Column(
              children: sortedLogs.take(10).map((log) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassmorphicCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        _StatusIcon(status: log.status),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log.scheduledTime.format('MMM d, h:mm a'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (log.takenTime != null)
                              Text(
                                '${l10n.takenAt}: ${log.takenTime!.format('h:mm a')}',
                                style: theme.textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const SizedBox(),
        ),
      ],
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});

  final MedicationLogStatus status;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (status) {
      case MedicationLogStatus.taken:
        icon = Icons.check_circle_rounded;
        color = Colors.green;
        break;
      case MedicationLogStatus.skipped:
        icon = Icons.remove_circle_rounded;
        color = Colors.grey;
        break;
      case MedicationLogStatus.missed:
        icon = Icons.cancel_rounded;
        color = Colors.red;
        break;
      case MedicationLogStatus.pending:
        icon = Icons.schedule_rounded;
        color = Colors.orange;
        break;
    }

    return Icon(icon, color: color);
  }
}

class _ComplianceChart extends StatelessWidget {
  const _ComplianceChart({required this.logs, required this.periodDays});

  final List<MedicationLog> logs;
  final int periodDays;

  @override
  Widget build(BuildContext context) {
    // Basic Bar Chart Implementation
    // Since implementing a full calendar chart or bar chart takes more code,
    // we'll implement a simple BarChart showing daily status for last 7 days for brevity,
    // or just a placeholder message if dataset is complex to map quickly.
    // The prompt requested 'green (taken), red (missed), gray (skipped)'.

    // Mapping data:
    // Group logs by day.
    // Create BarChartGroupData for each day.

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 1, // 100% or boolean status
        barTouchData: const BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                // Return day letter
                final date = DateTime.now().subtract(
                  Duration(days: 6 - value.toInt()),
                );
                return Text(DateFormat('E').format(date).substring(0, 1));
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
        barGroups: List.generate(7, (index) {
          final day = DateTime.now().subtract(Duration(days: 6 - index));
          // Find logs for this day
          final dayLogs = logs
              .where((l) => l.scheduledTime.isSameDay(day))
              .toList();

          var barColor = Colors.grey.withValues(
            alpha: 0.3,
          ); // Default no log or pending
          if (dayLogs.isNotEmpty) {
            // Prioritize missed > taken > skipped logic or similar
            if (dayLogs.any((l) => l.status == MedicationLogStatus.missed)) {
              barColor = Colors.red;
            } else if (dayLogs.any(
              (l) => l.status == MedicationLogStatus.taken,
            )) {
              barColor = Colors.green;
            } else if (dayLogs.any(
              (l) => l.status == MedicationLogStatus.skipped,
            )) {
              barColor = Colors.grey;
            }
          }

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: dayLogs.isNotEmpty
                    ? 1
                    : 0.1, // Full bar if data exists, small dot if empty
                color: barColor,
                width: 12,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
      ),
    );
  }
}
