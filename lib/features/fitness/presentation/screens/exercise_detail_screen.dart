/// VitalSync — Exercise Detail Screen
///
/// Displays detailed information about a specific exercise.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitalsync/core/l10n/app_localizations.dart';
import 'package:vitalsync/domain/entities/fitness/exercise.dart';
import 'package:vitalsync/presentation/widgets/fitness/glassmorphic_card.dart';

/// Screen showing full details for an [Exercise].
class ExerciseDetailScreen extends ConsumerWidget {
  /// Creates an exercise detail screen.
  const ExerciseDetailScreen({required this.exercise, super.key});

  /// The exercise to display.
  final Exercise exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.exerciseDetails)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with Icon and Name
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.fitness_center,
                      size: 40,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    exercise.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _TagChip(label: exercise.category.displayName),
                      _TagChip(label: exercise.muscleGroup),
                      _TagChip(label: exercise.equipment.displayName),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Instructions Section
            if (exercise.instructions != null &&
                exercise.instructions!.isNotEmpty) ...[
              Text(
                l10n.instructions,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              GlassmorphicCard(
                child: Text(
                  exercise.instructions!,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // History / PR Placeholders (Future Implementation)
            // We can add charts or stats here later
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      label: Text(label),
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      labelStyle: theme.textTheme.bodySmall,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
