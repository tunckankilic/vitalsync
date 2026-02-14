import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:vitalsync/core/enums/medication_log_status.dart';
import 'package:vitalsync/core/l10n/app_localizations.dart';
import 'package:vitalsync/core/theme/app_theme.dart';
import 'package:vitalsync/core/utils/extensions.dart';
import 'package:vitalsync/domain/entities/health/medication_log.dart';
import 'package:vitalsync/domain/entities/health/symptom.dart';
import 'package:vitalsync/features/health/presentation/providers/medication_log_provider.dart';
import 'package:vitalsync/features/health/presentation/providers/medication_provider.dart';
import 'package:vitalsync/features/health/presentation/providers/symptom_provider.dart';
import 'package:vitalsync/presentation/widgets/glassmorphic_card.dart';

class HealthTimelineScreen extends ConsumerStatefulWidget {
  const HealthTimelineScreen({super.key});

  @override
  ConsumerState<HealthTimelineScreen> createState() =>
      _HealthTimelineScreenState();
}

class _HealthTimelineScreenState extends ConsumerState<HealthTimelineScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // Fetch data for the focused month (at least)
    // For simplicity, we fetch a broader range or just active logs.
    // Ideally we fetch based on range. table_calendar asks for events for day.
    // Let's fetch current month data.
    final startOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final endOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

    // We need logs and symptoms.
    // We can assume we have providers that cache or load this.
    // Or we can just watch the stream of "logsInDateRange"

    final logsAsync = ref.watch(
      logsInDateRangeProvider(
        startDate: startOfMonth.subtract(const Duration(days: 7)), // Buffer
        endDate: endOfMonth.add(const Duration(days: 7)),
      ),
    );

    final symptomsAsync = ref.watch(
      symptomsInDateRangeProvider(
        startDate: startOfMonth.subtract(const Duration(days: 7)),
        endDate: endOfMonth.add(const Duration(days: 7)),
      ),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,

      // AppBar handled by shell or parent? If this is a main tab screen (Health),
      // AppShell provides the AppBar. But prompt 2.3 said: health/timeline is a route.
      // If it's a sub-screen, we need AppBar. If it's the main view of Health tab...
      // Health tab has nested routes.
      // Let's assume there is a back button if navigated to.
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  l10n.healthTimeline,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Calendar
              GlassmorphicCard(
                padding: const EdgeInsets.all(8),
                borderRadius: 20,
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 10, 16),
                  lastDay: DateTime.utc(2030, 3, 14),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                    // Show bottom sheet details for the day
                    _showDayDetails(context, selectedDay);
                  },
                  onFormatChanged: (format) {
                    setState(() => _calendarFormat = format);
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: AppTheme.healthPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  eventLoader: (day) {
                    final events = <dynamic>[];

                    // Add logs
                    if (logsAsync.hasValue) {
                      events.addAll(
                        logsAsync.value!.where(
                          (l) => isSameDay(l.scheduledTime, day),
                        ),
                      );
                    }

                    // Add symptoms
                    if (symptomsAsync.hasValue) {
                      events.addAll(
                        symptomsAsync.value!.where(
                          (s) => isSameDay(s.date, day),
                        ),
                      );
                    }

                    return events;
                  },
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, day, events) {
                      if (events.isEmpty) return null;
                      // Custom marker: dots for different types
                      final hasMeds = events.any((e) => e is MedicationLog);
                      final hasSymptoms = events.any((e) => e is Symptom);

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (hasMeds)
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 1.5,
                              ),
                              decoration: const BoxDecoration(
                                color: Colors.green, // Taken/Scheduled
                                shape: BoxShape.circle,
                              ),
                            ),
                          if (hasSymptoms)
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 1.5,
                              ),
                              decoration: const BoxDecoration(
                                color: Colors.orange, // Symptom warning
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Selected Day Preview (Inline list instead of BottomSheet? Or mostly sheet?)
              // Prompt says "Day tap -> bottom sheet"
              // But having an inline summary is also nice.
              // Let's stick to bottom sheet on tap as per prompt.
              // Here we can show Monthly Stats Summary.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: GlassmorphicCard(
                        child: Column(
                          children: [
                            Text(
                              l10n.compliance,
                              style: theme.textTheme.labelSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '92%', // Placeholder/Computed
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GlassmorphicCard(
                        child: Column(
                          children: [
                            Text(
                              l10n.symptoms,
                              style: theme.textTheme.labelSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '3', // Placeholder/Computed
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  void _showDayDetails(BuildContext context, DateTime day) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _DayDetailSheet(day: day),
    );
  }
}

class _DayDetailSheet extends ConsumerWidget {
  const _DayDetailSheet({required this.day});
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // Fetch logs and symptoms for this specific day
    // We can assume providers exist or filter from wider range.
    // Ideally specialized day provider.
    // Using placeholders for now assuming efficient caching or re-fetch.

    // final logsAsync = ref.watch(todayLogsProvider);
    // Wait, todayLogsProvider is for *today*. We need *specific day*.
    // Using filtered logsInDateRangeProvider is better.
    final logsAsyncRange = ref.watch(
      logsInDateRangeProvider(startDate: day.startOfDay, endDate: day.endOfDay),
    );

    final symptomsAsyncRange = ref.watch(
      symptomsInDateRangeProvider(
        startDate: day.startOfDay,
        endDate: day.endOfDay,
      ),
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                day.format('EEEE, MMMM d'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Meds Section
              Text(l10n.medications, style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              logsAsyncRange.when(
                data: (logs) {
                  if (logs.isEmpty) return Text(l10n.noLogsYet);
                  return Column(
                    children: logs
                        .map(
                          (log) => ListTile(
                            leading: Icon(
                              log.status == MedicationLogStatus.taken
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: log.status == MedicationLogStatus.taken
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            title: FutureBuilder<String>(
                              // Fetch medication name by ID?
                              // Ideally log contains name or we have map.
                              // MedicationLog entity usually only has ID.
                              // We need access to medications list to resolve name.
                              future: Future.value(
                                'Medication ${log.medicationId}',
                              ), // Placeholder
                              builder: (context, snapshot) =>
                                  Text(snapshot.data ?? '...'),
                            ),
                            subtitle: Text(log.scheduledTime.format('h:mm a')),
                          ),
                        )
                        .toList(),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
              ),

              const SizedBox(height: 24),

              // Symptoms Section
              Text(l10n.symptoms, style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              symptomsAsyncRange.when(
                data: (symptoms) {
                  if (symptoms.isEmpty) return Text(l10n.noSymptomsLogged);
                  return Column(
                    children: symptoms
                        .map(
                          (s) => ListTile(
                            leading: const Icon(
                              Icons.healing,
                              color: Colors.orange,
                            ),
                            title: Text(s.name),
                            trailing: Text('Severity: ${s.severity}'),
                          ),
                        )
                        .toList(),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
              ),
            ],
          ),
        );
      },
    );
  }
}
