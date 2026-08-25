/// VitalSync — Glucose List Screen.
///
/// Lists recorded blood glucose measurements, newest first.
///
/// No comment, only measurement: each row states the value, when it was
/// taken, where it came from and the context the user picked. Nothing is
/// scored, colour-coded or compared to a range.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:vitalsync/core/enums/glucose_unit.dart';
import 'package:vitalsync/core/l10n/app_localizations.dart';
import 'package:vitalsync/core/theme/app_theme.dart';
import 'package:vitalsync/core/utils/extensions.dart';
import 'package:vitalsync/domain/entities/health/glucose_reading.dart';
import 'package:vitalsync/features/health/presentation/confirm_delete_dialog.dart';
import 'package:vitalsync/features/health/presentation/health_labels.dart';
import 'package:vitalsync/features/health/presentation/providers/glucose_provider.dart';
import 'package:vitalsync/presentation/widgets/glassmorphic_card.dart';

class GlucoseListScreen extends ConsumerWidget {
  const GlucoseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final readingsAsync = ref.watch(glucoseReadingsProvider());

    return Scaffold(
      extendBodyBehindAppBar: true,
      // Transparent app bar purely for the automatic back button — this
      // screen is pushed on the root navigator (bottom nav hidden), so
      // without an app bar there is no way back. The in-body header keeps
      // the title.
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          IconButton(
            onPressed: () => context.push('/health/glucose/today'),
            icon: const Icon(Icons.show_chart_rounded),
            tooltip: l10n.glucoseToday,
          ),
        ],
      ),
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
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.glucoseReadings,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // A plain count, not an assessment.
                    readingsAsync.maybeWhen(
                      data: (readings) => Text(
                        l10n.glucoseReadingCount(readings.length),
                        style: theme.textTheme.bodySmall,
                      ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: readingsAsync.when(
                  data: (readings) {
                    if (readings.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.water_drop_outlined,
                              size: 48,
                              color: theme.disabledColor.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(l10n.noGlucoseReadings),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: readings.length,
                      itemBuilder: (context, index) {
                        final reading = readings[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          // Swipe to delete, mirroring the insight list.
                          // A mistyped measurement was previously permanent:
                          // `deleteReading` existed but nothing called it.
                          child: Dismissible(
                            key: Key('glucose_${reading.id}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            confirmDismiss: (_) => confirmDelete(
                              context,
                              title: l10n.deleteGlucoseReadingTitle,
                              message: l10n.deleteGlucoseReadingMessage,
                              confirmLabel: l10n.delete,
                              cancelLabel: l10n.cancel,
                            ),
                            onDismissed: (_) {
                              ref
                                  .read(glucoseProvider.notifier)
                                  .deleteReading(reading.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.glucoseReadingDeleted),
                                ),
                              );
                            },
                            child: _GlucoseCard(reading: reading),
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(
                    child: Text(AppLocalizations.of(context).errorGeneric(err)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/health/glucose/add'),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.logGlucoseReading),
        backgroundColor: AppTheme.healthPrimary,
      ),
    );
  }
}

class _GlucoseCard extends StatelessWidget {
  const _GlucoseCard({required this.reading});

  final GlucoseReading reading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // The list always reads in the storage unit; the unit toggle belongs to
    // the entry form, where the user picks how they type a value.
    const unit = GlucoseUnit.mgPerDl;

    return GlassmorphicCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                unit.formatMgDl(reading.valueMgDl),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(unit.label, style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reading.measuredAt.format('MMM d, HH:mm'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  reading.mealContext?.label(l10n) ?? l10n.glucoseContextNone,
                  style: theme.textTheme.bodySmall,
                ),
                if (reading.notes != null && reading.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    reading.notes!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: theme.disabledColor),
                  ),
                ],
              ],
            ),
          ),
          Tooltip(
            message: reading.source.label(l10n),
            child: Icon(
              reading.source.isImported
                  ? Icons.favorite_rounded
                  : Icons.edit_rounded,
              size: 18,
              color: theme.disabledColor,
            ),
          ),
        ],
      ),
    );
  }
}
