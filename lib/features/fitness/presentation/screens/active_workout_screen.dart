/// VitalSync — Active Workout Screen
///
/// CRITICAL GYM-READY SCREEN
/// High contrast, large touch targets, one-handed operation.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitalsync/core/l10n/app_localizations.dart';
import 'package:vitalsync/presentation/widgets/fitness/glassmorphic_card.dart';
import 'package:vitalsync/presentation/widgets/fitness/pr_badge.dart';

import '../../../../presentation/widgets/fitness/rest_timer_widget.dart';
import '../providers/workout_provider.dart';

/// Active workout screen for gym use.
///
/// Features:
/// - Elapsed timer
/// - Set logging with weight/reps inputs
/// - Rest timer with haptic feedback
/// - PR detection and celebration
/// - Exercise navigator
/// - High contrast design
/// - Large touch targets (56x56 minimum)
class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  /// Creates an active workout screen.
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  Timer? _elapsedTimer;
  int _elapsedSeconds = 0;
  bool _showRestTimer = false;
  final int _restDuration = 90; // Default 90 seconds
  int? _currentExerciseId;
  final Map<int, bool> _prAchieved = {};

  @override
  void initState() {
    super.initState();
    _startElapsedTimer();
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    super.dispose();
  }

  void _startElapsedTimer() {
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  String _formatElapsedTime() {
    final hours = _elapsedSeconds ~/ 3600;
    final minutes = (_elapsedSeconds % 3600) ~/ 60;
    final seconds = _elapsedSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final activeSession = ref.watch(activeSessionProvider);

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBackPressed(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l10n.activeWorkout,
            style: const TextStyle(
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          centerTitle: false,
          actions: [
            // Elapsed timer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  _formatElapsedTime(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            // Finish button
            TextButton(
              onPressed: () => _handleFinishWorkout(context),
              child: Text(l10n.finishWorkout),
            ),
          ],
        ),
        body: activeSession.when(
          data: (session) {
            if (session == null) {
              return _buildNoActiveSession(context);
            }
            return _buildActiveWorkout(context, session);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  Widget _buildNoActiveSession(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.fitness_center, size: 64),
          const SizedBox(height: 16),
          Text(l10n.noWorkoutsYet),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.startWorkout),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveWorkout(BuildContext context, dynamic session) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        // Current Exercise Card
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CurrentExerciseCard(
                  exerciseName: 'Bench Press', // Mock data
                  muscleGroup: 'Chest',
                  equipment: 'Barbell',
                  previousSets: '80kg × 10, 80kg × 8, 75kg × 10',
                ),
                const SizedBox(height: 24),

                // Set Logger
                _SetLoggerSection(onSetCompleted: _handleSetCompleted),
                const SizedBox(height: 24),

                // Rest Timer (conditional)
                if (_showRestTimer)
                  RestTimerWidget(
                    durationSeconds: _restDuration,
                    onComplete: () {
                      setState(() {
                        _showRestTimer = false;
                      });
                    },
                    onSkip: () {
                      setState(() {
                        _showRestTimer = false;
                      });
                    },
                  ),
              ],
            ),
          ),
        ),

        // Exercise Navigator (bottom)
        _ExerciseNavigator(
          exercises: const ['Bench Press', 'Squat', 'Deadlift'], // Mock
          currentIndex: 0,
          onExerciseSelected: (index) {
            // Handle exercise switch
          },
        ),
      ],
    );
  }

  void _handleSetCompleted(double weight, int reps, bool isWarmup) async {
    // Trigger haptic
    await HapticFeedback.mediumImpact();

    // Check for PR (mock logic)
    final isPR = weight > 100; // Simplified PR detection

    if (isPR) {
      setState(() {
        _prAchieved[0] = true;
      });
      await HapticFeedback.heavyImpact();
    }

    // Start rest timer
    if (!isWarmup) {
      setState(() {
        _showRestTimer = true;
      });
    }
  }

  Future<bool> _handleBackPressed(BuildContext context) async {
    final l10n = AppLocalizations.of(context);

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.discardWorkout),
        content: Text(l10n.discardWorkoutMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.dismiss),
          ),
        ],
      ),
    );

    return shouldDiscard ?? false;
  }

  void _handleFinishWorkout(BuildContext context) {
    // Navigate to workout summary
    Navigator.pushReplacementNamed(context, '/fitness/summary');
  }
}

/// Current exercise card showing exercise details and previous session data.
class _CurrentExerciseCard extends StatelessWidget {
  const _CurrentExerciseCard({
    required this.exerciseName,
    required this.muscleGroup,
    required this.equipment,
    required this.previousSets,
  });

  final String exerciseName;
  final String muscleGroup;
  final String equipment;
  final String previousSets;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return GlassmorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exerciseName,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              Chip(
                label: Text(muscleGroup),
                visualDensity: VisualDensity.compact,
              ),
              Chip(
                label: Text(equipment),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${l10n.previousSession}: $previousSets',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

/// Set logger section with weight/reps inputs and complete button.
class _SetLoggerSection extends StatefulWidget {
  const _SetLoggerSection({required this.onSetCompleted});

  final void Function(double weight, int reps, bool isWarmup) onSetCompleted;

  @override
  State<_SetLoggerSection> createState() => _SetLoggerSectionState();
}

class _SetLoggerSectionState extends State<_SetLoggerSection> {
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  bool _isWarmup = false;
  final List<Map<String, dynamic>> _completedSets = [];

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Completed sets
        if (_completedSets.isNotEmpty) ...[
          ..._completedSets.asMap().entries.map((entry) {
            final index = entry.key;
            final set = entry.value;
            return _CompletedSetRow(
              setNumber: index + 1,
              weight: set['weight'] as double,
              reps: set['reps'] as int,
              isWarmup: set['isWarmup'] as bool,
              isPR: set['isPR'] as bool? ?? false,
            );
          }),
          const SizedBox(height: 16),
        ],

        // Current set input
        GlassmorphicCard(
          child: Column(
            children: [
              Row(
                children: [
                  // Weight input
                  Expanded(
                    child: TextField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      style: theme.textTheme.headlineSmall,
                      decoration: InputDecoration(
                        labelText: l10n.weight,
                        suffixText: l10n.kg,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text('×', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 16),
                  // Reps input
                  Expanded(
                    child: TextField(
                      controller: _repsController,
                      keyboardType: TextInputType.number,
                      style: theme.textTheme.headlineSmall,
                      decoration: InputDecoration(
                        labelText: l10n.reps,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  // Warmup toggle
                  Expanded(
                    child: CheckboxListTile(
                      title: Text(l10n.warmup),
                      value: _isWarmup,
                      onChanged: (value) {
                        setState(() {
                          _isWarmup = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
                  // Complete button
                  ElevatedButton.icon(
                    onPressed: _handleComplete,
                    icon: const Icon(Icons.check),
                    label: Text(l10n.completeSet),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(120, 56),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleComplete() {
    final weight = double.tryParse(_weightController.text);
    final reps = int.tryParse(_repsController.text);

    if (weight == null || reps == null) return;

    // Mock PR detection
    final isPR = weight > 100;

    setState(() {
      _completedSets.add({
        'weight': weight,
        'reps': reps,
        'isWarmup': _isWarmup,
        'isPR': isPR,
      });
      _weightController.clear();
      _repsController.clear();
      _isWarmup = false;
    });

    widget.onSetCompleted(weight, reps, _isWarmup);
  }
}

/// Completed set row with green flash animation.
class _CompletedSetRow extends StatelessWidget {
  const _CompletedSetRow({
    required this.setNumber,
    required this.weight,
    required this.reps,
    required this.isWarmup,
    required this.isPR,
  });

  final int setNumber;
  final double weight;
  final int reps;
  final bool isWarmup;
  final bool isPR;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: isPR
            ? Border.all(color: const Color(0xFFFFD700), width: 2)
            : null,
      ),
      child: Row(
        children: [
          Text(
            l10n.setNumber(setNumber),
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          Text('$weight ${l10n.kg} × $reps', style: theme.textTheme.bodyLarge),
          if (isWarmup) ...[
            const SizedBox(width: 8),
            Chip(
              label: Text(l10n.warmup),
              visualDensity: VisualDensity.compact,
            ),
          ],
          const Spacer(),
          if (isPR)
            const PRBadge(size: 16, animate: false)
          else
            const Icon(Icons.check_circle, color: Colors.green),
        ],
      ),
    );
  }
}

/// Exercise navigator with horizontal pill list.
class _ExerciseNavigator extends StatelessWidget {
  const _ExerciseNavigator({
    required this.exercises,
    required this.currentIndex,
    required this.onExerciseSelected,
  });

  final List<String> exercises;
  final int currentIndex;
  final void Function(int index) onExerciseSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: exercises.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (index == exercises.length) {
                  return _AddExerciseButton();
                }

                final isActive = index == currentIndex;
                return _ExercisePill(
                  name: exercises[index],
                  isActive: isActive,
                  isCompleted: index < currentIndex,
                  onTap: () => onExerciseSelected(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ExercisePill extends StatelessWidget {
  const _ExercisePill({
    required this.name,
    required this.isActive,
    required this.isCompleted,
    required this.onTap,
  });

  final String name;
  final bool isActive;
  final bool isCompleted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCompleted)
              const Icon(Icons.check_circle, size: 16, color: Colors.green),
            if (isCompleted) const SizedBox(width: 4),
            Text(
              name,
              style: TextStyle(
                color: isActive
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddExerciseButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return GestureDetector(
      onTap: () {
        // Show exercise library
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.primary),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              l10n.addExercise,
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
