/// VitalSync — Meal List Screen.
///
/// Lists logged meals, newest first.
///
/// No comment, only measurement: each row states the name, the time and the
/// tags the user picked. Nothing here ranks a meal or relates it to a
/// glucose reading.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:vitalsync/core/l10n/app_localizations.dart';
import 'package:vitalsync/core/theme/app_theme.dart';
import 'package:vitalsync/core/utils/extensions.dart';
import 'package:vitalsync/domain/entities/health/meal.dart';
import 'package:vitalsync/features/health/presentation/providers/meal_provider.dart';
import 'package:vitalsync/presentation/widgets/glassmorphic_card.dart';

class MealListScreen extends ConsumerWidget {
  const MealListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final mealsAsync = ref.watch(mealsProvider());

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
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _MealCard(meal: meals[index]),
                      ),
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
  const _MealCard({required this.meal});

  final Meal meal;

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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
