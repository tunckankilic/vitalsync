/// VitalSync — Calendar Screen.
///
/// Workout calendar with heat-map style visualization.
/// Shows workout days, streak data, and monthly statistics.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:vitalsync/core/l10n/app_localizations.dart';
import 'package:vitalsync/core/theme/app_theme.dart';
import 'package:vitalsync/features/fitness/presentation/providers/streak_provider.dart';
import 'package:vitalsync/presentation/widgets/glassmorphic_app_bar.dart';
import 'package:vitalsync/presentation/widgets/glassmorphic_card.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final calendarDataAsync = ref.watch(calendarDataProvider(_focusedDay));
    final currentStreakAsync = ref.watch(currentStreakProvider);
    final longestStreakAsync = ref.watch(longestStreakProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassmorphicAppBar(title: l10n.calendar),
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
              // Streak Stats Card
              _StreakStatsCard(
                currentStreakAsync: currentStreakAsync,
                longestStreakAsync: longestStreakAsync,
              ),

              const SizedBox(height: 16),

              // Calendar
              GlassmorphicCard(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: calendarDataAsync.when(
                    data: (calendarData) {
                      return TableCalendar<void>(
                        firstDay: DateTime.utc(2020),
                        lastDay: DateTime.utc(2030),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) =>
                            isSameDay(_selectedDay, day),
                        calendarFormat: _calendarFormat,
                        onFormatChanged: (format) {
                          setState(() => _calendarFormat = format);
                        },
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        onPageChanged: (focusedDay) {
                          setState(() => _focusedDay = focusedDay);
                        },
                        calendarStyle: CalendarStyle(
                          outsideDaysVisible: false,
                          todayDecoration: BoxDecoration(
                            color: AppTheme.fitnessPrimary.withValues(
                              alpha: 0.3,
                            ),
                            shape: BoxShape.circle,
                          ),
                          todayTextStyle: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                          selectedDecoration: const BoxDecoration(
                            color: AppTheme.fitnessPrimary,
                            shape: BoxShape.circle,
                          ),
                          selectedTextStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          defaultTextStyle: TextStyle(
                            color: theme.colorScheme.onSurface,
                          ),
                          weekendTextStyle: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                        headerStyle: HeaderStyle(
                          formatButtonVisible: true,
                          titleCentered: true,
                          titleTextStyle: theme.textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          formatButtonDecoration: BoxDecoration(
                            border: Border.all(color: AppTheme.fitnessPrimary),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          formatButtonTextStyle: const TextStyle(
                            color: AppTheme.fitnessPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          leftChevronIcon: Icon(
                            Icons.chevron_left,
                            color: theme.colorScheme.onSurface,
                          ),
                          rightChevronIcon: Icon(
                            Icons.chevron_right,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        calendarBuilders: CalendarBuilders(
                          defaultBuilder: (context, day, focusedDay) {
                            final normalizedDay = DateTime(
                              day.year,
                              day.month,
                              day.day,
                            );
                            final hasWorkout = _hasWorkoutOnDay(
                              calendarData,
                              normalizedDay,
                            );

                            if (hasWorkout) {
                              return Container(
                                margin: const EdgeInsets.all(4),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppTheme.fitnessPrimary.withValues(
                                    alpha: 0.7,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${day.day}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }
                            return null;
                          },
                          todayBuilder: (context, day, focusedDay) {
                            final normalizedDay = DateTime(
                              day.year,
                              day.month,
                              day.day,
                            );
                            final hasWorkout = _hasWorkoutOnDay(
                              calendarData,
                              normalizedDay,
                            );

                            return Container(
                              margin: const EdgeInsets.all(4),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: hasWorkout
                                    ? AppTheme.fitnessPrimary
                                    : AppTheme.fitnessPrimary.withValues(
                                        alpha: 0.2,
                                      ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.fitnessPrimary,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                '${day.day}',
                                style: TextStyle(
                                  color: hasWorkout
                                      ? Colors.white
                                      : theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    loading: () => const SizedBox(
                      height: 350,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, _) => SizedBox(
                      height: 350,
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context).errorLoadingCalendar,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Monthly Stats
              _MonthlyStatsCard(
                calendarDataAsync: calendarDataAsync,
                focusedDay: _focusedDay,
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasWorkoutOnDay(Map<DateTime, bool> calendarData, DateTime day) {
    for (final entry in calendarData.entries) {
      final entryDay = DateTime(entry.key.year, entry.key.month, entry.key.day);
      if (entryDay == day && entry.value) {
        return true;
      }
    }
    return false;
  }
}

class _StreakStatsCard extends StatelessWidget {
  const _StreakStatsCard({
    required this.currentStreakAsync,
    required this.longestStreakAsync,
  });

  final AsyncValue<int> currentStreakAsync;
  final AsyncValue<int> longestStreakAsync;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                currentStreakAsync.when(
                  data: (streak) => Text(
                    '$streak',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.fitnessPrimary,
                    ),
                  ),
                  loading: () => const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, _) =>
                      Text('-', style: theme.textTheme.headlineMedium),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.currentStreak,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            Container(
              width: 1,
              height: 40,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            Column(
              children: [
                longestStreakAsync.when(
                  data: (streak) => Text(
                    '$streak',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.fitnessSecondary,
                    ),
                  ),
                  loading: () => const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, _) =>
                      Text('-', style: theme.textTheme.headlineMedium),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.streak,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyStatsCard extends StatelessWidget {
  const _MonthlyStatsCard({
    required this.calendarDataAsync,
    required this.focusedDay,
  });

  final AsyncValue<Map<DateTime, bool>> calendarDataAsync;
  final DateTime focusedDay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.monthlyStats,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            calendarDataAsync.when(
              data: (calendarData) {
                // Count workouts in the focused month
                final workoutDays = calendarData.entries
                    .where(
                      (e) =>
                          e.value &&
                          e.key.month == focusedDay.month &&
                          e.key.year == focusedDay.year,
                    )
                    .length;

                final daysInMonth = DateUtils.getDaysInMonth(
                  focusedDay.year,
                  focusedDay.month,
                );

                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.fitness_center,
                                size: 16,
                                color: AppTheme.fitnessPrimary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l10n.totalWorkouts,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$workoutDays',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.percent,
                                size: 16,
                                color: AppTheme.fitnessSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l10n.compliance,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${daysInMonth > 0 ? (workoutDays * 100 / daysInMonth).round() : 0}%',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
              loading: () => const SizedBox(
                height: 50,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => Text('-', style: theme.textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}
