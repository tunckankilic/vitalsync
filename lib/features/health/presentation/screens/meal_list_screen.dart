/// VitalSync — Meal List Screen.
///
/// Lists logged meals, newest first.
///
/// No comment, only measurement: each row states the name, the time, the
/// tags the user picked, and whether measurement data exists around it.
/// Nothing here ranks a meal or says anything about the readings themselves.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:vitalsync/core/l10n/app_localizations.dart';
import 'package:vitalsync/core/theme/app_theme.dart';
import 'package:vitalsync/core/utils/extensions.dart';
import 'package:vitalsync/domain/entities/health/meal.dart';
import 'package:vitalsync/features/health/domain/services/meal_data_coverage_service.dart';
import 'package:vitalsync/features/health/presentation/confirm_delete_dialog.dart';
import 'package:vitalsync/features/health/presentation/health_labels.dart';
import 'package:vitalsync/features/health/presentation/providers/meal_provider.dart';
import 'package:vitalsync/presentation/widgets/glassmorphic_card.dart';

class MealListScreen extends ConsumerWidget {
  const MealListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final mealsAsync = ref.watch(mealsProvider());
    // Data completeness only: whether measurements exist around a meal,
    // never anything about the measurements themselves.
    final coverage = ref.watch(mealCoverageProvider()).value;

    return Scaffold(
      extendBodyBehindAppBar: true,
      // Transparent app bar purely for the automatic back button — this
      // screen is pushed on the root navigator (bottom nav hidden), so
      // without an app bar there is no way back.
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
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
                        l10n.meals,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // A plain count, not an assessment.
                    mealsAsync.maybeWhen(
                      data: (meals) => Text(
                        l10n.mealCount(meals.length),
                        style: theme.textTheme.bodySmall,
                      ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: mealsAsync.when(
                  data: (meals) {
                    if (meals.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.restaurant_rounded,
                              size: 48,
                              color: theme.disabledColor.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(l10n.noMealsLogged),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: meals.length,
                      itemBuilder: (context, index) {
                        final meal = meals[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          // Swipe to delete, mirroring the insight list.
                          // `deleteMeal` existed but nothing called it, so a
                          // mistyped meal was permanent — and it kept
                          // counting against the coverage tally.
                          child: Dismissible(
                            key: Key('meal_${meal.id}'),
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
                              title: l10n.deleteMealTitle,
                              message: l10n.deleteMealMessage,
                              confirmLabel: l10n.delete,
                              cancelLabel: l10n.cancel,
                            ),
                            onDismissed: (_) {
                              // Also cancels the pending post-meal reminder.
                              ref
                                  .read(mealProvider.notifier)
                                  .deleteMeal(meal.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.mealDeleted)),
                              );
                            },
                            child: _MealCard(
                              meal: meal,
                              coverage: coverage?[meal.id],
                            ),
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
        onPressed: () => context.push('/health/meals/add'),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.logMeal),
        backgroundColor: AppTheme.healthPrimary,
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({required this.meal, this.coverage});

  final Meal meal;

  /// Null while the verdicts are still loading.
  final MealCoverage? coverage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassmorphicCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.restaurant_rounded,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  meal.eatenAt.format('MMM d, HH:mm'),
                  style: theme.textTheme.bodySmall,
                ),
                if (meal.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: meal.tags
                        .map(
                          (tag) => Chip(
                            label: Text(tag),
                            labelStyle: theme.textTheme.labelSmall,
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (meal.notes != null && meal.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    meal.notes!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: theme.disabledColor),
                  ),
                ],
                if (coverage != null) ...[
                  const SizedBox(height: 8),
                  _CoverageBadge(coverage: coverage!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// States whether measurements exist around a meal, and if not, why.
///
/// A statement about the recording, not about the meal or the user. The
/// colours are the theme's neutral roles on purpose — nothing here reads as
/// "good" or "bad".
class _CoverageBadge extends StatelessWidget {
  const _CoverageBadge({required this.coverage});

  final MealCoverage coverage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final label = coverage.isCovered
        ? l10n.mealCoverageCovered
        : '${l10n.mealCoverageUncovered} · ${coverage.reason!.label(l10n)}';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          coverage.isCovered
              ? Icons.check_circle_outline_rounded
              : Icons.remove_circle_outline_rounded,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
