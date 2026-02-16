/// VitalSync — Exercise Library Screen
///
/// Clean list of exercises with search and filter.
/// Used for exploring exercises or selecting one for a workout.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vitalsync/core/l10n/app_localizations.dart';
import 'package:vitalsync/domain/entities/fitness/exercise.dart';
import 'package:vitalsync/presentation/widgets/fitness/glassmorphic_card.dart';

import '../providers/exercise_provider.dart';
import '../widgets/add_exercise_dialog.dart';
import 'exercise_detail_screen.dart';

/// Screen for browsing exercises or selecting one.
class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  /// Creates an exercise library screen.
  /// [isSelectionMode] - If true, tapping an exercise returns it.
  const ExerciseLibraryScreen({super.key, this.isSelectionMode = false});

  final bool isSelectionMode;

  @override
  ConsumerState<ExerciseLibraryScreen> createState() =>
      _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final exercisesAsync = _searchQuery.isEmpty
        ? ref.watch(exercisesProvider)
        : ref.watch(exerciseSearchProvider(_searchQuery));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.exerciseLibrary)),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchExercises,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Exercise List
          Expanded(
            child: exercisesAsync.when(
              data: (exercises) {
                if (exercises.isEmpty) {
                  return Center(child: Text(l10n.noExercisesFound));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: exercises.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    return _ExerciseCard(
                      exercise: exercise,
                      onTap: () {
                        if (widget.isSelectionMode) {
                          context.pop(exercise);
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  ExerciseDetailScreen(exercise: exercise),
                            ),
                          );
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text(AppLocalizations.of(context).errorGeneric(err))),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddExerciseDialog(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.exercise, required this.onTap});

  final Exercise exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: GlassmorphicCard(
        child: Row(
          children: [
            // Simplified placeholder image or icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.fitness_center,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    exercise.muscleGroup,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
