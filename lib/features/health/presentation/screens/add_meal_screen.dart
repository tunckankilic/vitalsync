/// VitalSync — Add Meal Screen.
///
/// Photo-free meal entry: name, time, tags and an optional note.
///
/// No comment, only measurement: the form records what the user says they
/// ate and when. There is no photo, no camera permission, no nutrient
/// estimate and no assessment of the meal.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:vitalsync/core/enums/sync_status.dart';
import 'package:vitalsync/core/l10n/app_localizations.dart';
import 'package:vitalsync/core/theme/app_theme.dart';
import 'package:vitalsync/core/utils/extensions.dart';
import 'package:vitalsync/domain/entities/health/meal.dart';
import 'package:vitalsync/features/health/presentation/providers/meal_provider.dart';
import 'package:vitalsync/presentation/widgets/glassmorphic_app_bar.dart';
import 'package:vitalsync/presentation/widgets/glassmorphic_card.dart';

class AddMealScreen extends ConsumerStatefulWidget {
  const AddMealScreen({super.key});

  @override
  ConsumerState<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends ConsumerState<AddMealScreen> {
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  final List<String> _selectedTags = [];
  bool _isLoading = false;

  List<String> _commonTags(AppLocalizations l10n) => [
    l10n.mealTagBreakfast,
    l10n.mealTagLunch,
    l10n.mealTagDinner,
    l10n.mealTagSnack,
    l10n.mealTagDrink,
    l10n.mealTagEatingOut,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);

    if (_nameController.text.trim().isEmpty) {
      context.showErrorSnackbar(l10n.pleaseEnterMealName);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final meal = Meal(
        id: 0, // auto-inc
        name: _nameController.text.trim(),
        eatenAt: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        ),
        tags: List.unmodifiable(_selectedTags),
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        syncStatus: SyncStatus.pending,
        lastModifiedAt: now,
        createdAt: now,
      );

      await ref.read(mealProvider.notifier).addMeal(meal);

      if (mounted) {
        context.showSuccessSnackbar(l10n.mealLoggedSuccess);
        context.pop();
      }
    } catch (e) {
      // The meal name is never surfaced in the error — health data does not
      // go into log or crash-report strings.
      if (mounted) {
        context.showErrorSnackbar(
          AppLocalizations.of(context).errorLoggingMeal(e),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final commonTags = _commonTags(l10n);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassmorphicAppBar(title: l10n.logMeal),
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
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Name
              GlassmorphicCard(
                child: TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.mealName,
                    prefixIcon: const Icon(Icons.restaurant_rounded),
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Date & time
              GlassmorphicCard(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(l10n.date),
                      trailing: Text(_selectedDate.format('MMM d, yyyy')),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                      dense: true,
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: Text(l10n.time),
                      trailing: Text(_selectedTime.format(context)),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime,
                        );
                        if (picked != null) {
                          setState(() => _selectedTime = picked);
                        }
                      },
                      dense: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tags
              GlassmorphicCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.mealTags, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: commonTags.map((tag) {
                        return FilterChip(
                          label: Text(tag),
                          selected: _selectedTags.contains(tag),
                          onSelected: (selected) => setState(() {
                            if (selected) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.remove(tag);
                            }
                          }),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Notes
              GlassmorphicCard(
                child: TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: l10n.notes,
                    prefixIcon: const Icon(Icons.note),
                    border: InputBorder.none,
                  ),
                  maxLines: 3,
                ),
              ),

              const SizedBox(height: 24),

              // Save
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _save,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(_isLoading ? l10n.saving : l10n.save),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.healthPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
