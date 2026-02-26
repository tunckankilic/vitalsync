/// VitalSync — Add/Edit Workout Template Screen.
///
/// Form for creating or editing workout templates:
/// - Template name + color picker (8 colors)
/// - Exercise selection from exercise library
/// - Default sets, reps, weight, rest per exercise
/// - ReorderableListView for exercise ordering
/// - Form validation + save
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../domain/entities/fitness/exercise.dart';
import '../../../../domain/entities/fitness/template_exercise.dart';
import '../../../../domain/entities/fitness/workout_template.dart';
import '../../../../presentation/widgets/glassmorphic_card.dart';
import '../providers/workout_provider.dart';

/// Available template colors.
const _templateColors = [
  Color(0xFF4CAF50), // Green
  Color(0xFF2196F3), // Blue
  Color(0xFFFF9800), // Orange
  Color(0xFFE91E63), // Pink
  Color(0xFF9C27B0), // Purple
  Color(0xFF00BCD4), // Cyan
  Color(0xFFFF5722), // Deep Orange
  Color(0xFF607D8B), // Blue Grey
];

/// Screen for creating or editing a workout template.
class AddEditTemplateScreen extends ConsumerStatefulWidget {
  const AddEditTemplateScreen({super.key, this.template});

  /// If provided, we're editing an existing template.
  final WorkoutTemplate? template;

  @override
  ConsumerState<AddEditTemplateScreen> createState() =>
      _AddEditTemplateScreenState();
}

class _AddEditTemplateScreenState extends ConsumerState<AddEditTemplateScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late Color _selectedColor;
  late int _estimatedDuration;
  final List<_TemplateExerciseEntry> _exercises = [];
  bool _isSaving = false;

  bool get _isEditing => widget.template != null;

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    _nameController = TextEditingController(text: t?.name ?? '');
    _descriptionController = TextEditingController(text: t?.description ?? '');
    _selectedColor = t != null ? Color(t.color) : _templateColors.first;
    _estimatedDuration = t?.estimatedDuration ?? 60;

    if (t != null && t.exercises.isNotEmpty) {
      for (final te in t.exercises) {
        _exercises.add(_TemplateExerciseEntry(
          exerciseId: te.exerciseId,
          exerciseName: te.exercise?.name ?? 'Exercise #${te.exerciseId}',
          defaultSets: te.defaultSets,
          defaultReps: te.defaultReps,
          defaultWeight: te.defaultWeight,
          restSeconds: te.restSeconds,
        ));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickExercise() async {
    final result = await context.push<Exercise>('/fitness/exercises?selection=true');
    if (result != null && mounted) {
      setState(() {
        _exercises.add(_TemplateExerciseEntry(
          exerciseId: result.id,
          exerciseName: result.name,
          defaultSets: 3,
          defaultReps: 10,
          restSeconds: 90,
        ));
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(workoutTemplateRepositoryProvider);
      final now = DateTime.now();

      final templateData = WorkoutTemplate(
        id: widget.template?.id ?? 0,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        color: _selectedColor.toARGB32(),
        estimatedDuration: _estimatedDuration,
        isDefault: widget.template?.isDefault ?? false,
        createdAt: widget.template?.createdAt ?? now,
        updatedAt: now,
        exercises: [],
      );

      if (_isEditing) {
        await repo.update(templateData);
        // Update exercises: remove old, add new
        final oldExercises = await repo.getTemplateExercises(templateData.id);
        for (final old in oldExercises) {
          await repo.removeExerciseFromTemplate(templateData.id, old.exerciseId);
        }
        for (var i = 0; i < _exercises.length; i++) {
          final entry = _exercises[i];
          await repo.addExerciseToTemplate(
            templateData.id,
            TemplateExercise(
              id: 0,
              templateId: templateData.id,
              exerciseId: entry.exerciseId,
              orderIndex: i,
              defaultSets: entry.defaultSets,
              defaultReps: entry.defaultReps,
              defaultWeight: entry.defaultWeight,
              restSeconds: entry.restSeconds,
            ),
          );
        }
      } else {
        final newId = await repo.insert(templateData);
        for (var i = 0; i < _exercises.length; i++) {
          final entry = _exercises[i];
          await repo.addExerciseToTemplate(
            newId,
            TemplateExercise(
              id: 0,
              templateId: newId,
              exerciseId: entry.exerciseId,
              orderIndex: i,
              defaultSets: entry.defaultSets,
              defaultReps: entry.defaultReps,
              defaultWeight: entry.defaultWeight,
              restSeconds: entry.restSeconds,
            ),
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).templateSaved)),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).errorGeneric(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editTemplate : l10n.createTemplate),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.save),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Template Name & Description
            GlassmorphicCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: l10n.templateName,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.requiredField;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: l10n.notes,
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Color Picker
            GlassmorphicCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.color,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _templateColors.map((color) {
                        final isSelected = _selectedColor.toARGB32() == color.toARGB32();
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = color),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: isSelected ? 40 : 32,
                            height: isSelected ? 40 : 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                      color: theme.colorScheme.onSurface,
                                      width: 3,
                                    )
                                  : null,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Estimated Duration
            GlassmorphicCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.estimatedDuration,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    DropdownButton<int>(
                      value: _estimatedDuration,
                      items: [15, 30, 45, 60, 75, 90, 120].map((min) {
                        return DropdownMenuItem(
                          value: min,
                          child: Text('$min ${l10n.minutesShort}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _estimatedDuration = val);
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Exercises Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.exerciseCount,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: _pickExercise,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.addExerciseToTemplate),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_exercises.isEmpty)
              GlassmorphicCard(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      l10n.selectExercises,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                proxyDecorator: (child, index, animation) {
                  return AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) {
                      final scale = 1.0 + Curves.easeInOut.transform(animation.value) * 0.02;
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: child,
                  );
                },
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) newIndex -= 1;
                    final item = _exercises.removeAt(oldIndex);
                    _exercises.insert(newIndex, item);
                  });
                },
                itemCount: _exercises.length,
                itemBuilder: (context, index) {
                  final entry = _exercises[index];
                  return _ExerciseEntryCard(
                    key: ValueKey('exercise_${entry.exerciseId}_$index'),
                    entry: entry,
                    index: index,
                    onRemove: () {
                      setState(() => _exercises.removeAt(index));
                    },
                    onChanged: (updated) {
                      setState(() => _exercises[index] = updated);
                    },
                  );
                },
              ),

            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
    );
  }
}

/// Internal model for exercise entries during editing.
class _TemplateExerciseEntry {
  _TemplateExerciseEntry({
    required this.exerciseId,
    required this.exerciseName,
    required this.defaultSets,
    required this.defaultReps,
    required this.restSeconds,
    this.defaultWeight,
  });

  final int exerciseId;
  final String exerciseName;
  int defaultSets;
  int defaultReps;
  double? defaultWeight;
  int restSeconds;
}

class _ExerciseEntryCard extends StatelessWidget {
  const _ExerciseEntryCard({
    required super.key,
    required this.entry,
    required this.index,
    required this.onRemove,
    required this.onChanged,
  });

  final _TemplateExerciseEntry entry;
  final int index;
  final VoidCallback onRemove;
  final ValueChanged<_TemplateExerciseEntry> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassmorphicCard(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Exercise header row
              Row(
                children: [
                  ReorderableDragStartListener(
                    index: index,
                    child: Icon(
                      Icons.drag_handle,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.exerciseName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: onRemove,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Default values row
              Row(
                children: [
                  // Sets
                  _CompactInput(
                    label: l10n.sets,
                    value: entry.defaultSets,
                    onChanged: (v) {
                      entry.defaultSets = v;
                      onChanged(entry);
                    },
                  ),
                  const SizedBox(width: 8),
                  // Reps
                  _CompactInput(
                    label: l10n.reps,
                    value: entry.defaultReps,
                    onChanged: (v) {
                      entry.defaultReps = v;
                      onChanged(entry);
                    },
                  ),
                  const SizedBox(width: 8),
                  // Weight
                  _CompactDoubleInput(
                    label: l10n.weight,
                    value: entry.defaultWeight,
                    onChanged: (v) {
                      entry.defaultWeight = v;
                      onChanged(entry);
                    },
                  ),
                  const SizedBox(width: 8),
                  // Rest
                  _CompactInput(
                    label: '${l10n.restTime} (s)',
                    value: entry.restSeconds,
                    onChanged: (v) {
                      entry.restSeconds = v;
                      onChanged(entry);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactInput extends StatelessWidget {
  const _CompactInput({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 36,
            child: TextFormField(
              initialValue: value.toString(),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
              ),
              onChanged: (text) {
                final parsed = int.tryParse(text);
                if (parsed != null && parsed > 0) onChanged(parsed);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactDoubleInput extends StatelessWidget {
  const _CompactDoubleInput({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double? value;
  final ValueChanged<double?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 36,
            child: TextFormField(
              initialValue: value?.toStringAsFixed(1) ?? '',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
                hintText: '-',
              ),
              onChanged: (text) {
                if (text.isEmpty) {
                  onChanged(null);
                } else {
                  final parsed = double.tryParse(text);
                  if (parsed != null && parsed >= 0) onChanged(parsed);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
