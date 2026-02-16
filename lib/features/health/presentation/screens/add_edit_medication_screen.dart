import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:vitalsync/core/enums/medication_frequency.dart';
import 'package:vitalsync/core/enums/sync_status.dart';
import 'package:vitalsync/core/l10n/app_localizations.dart';
import 'package:vitalsync/core/theme/app_theme.dart';
import 'package:vitalsync/core/utils/extensions.dart';
import 'package:vitalsync/domain/entities/health/medication.dart';
import 'package:vitalsync/features/health/presentation/providers/medication_provider.dart';
import 'package:vitalsync/presentation/widgets/glassmorphic_app_bar.dart';
import 'package:vitalsync/presentation/widgets/glassmorphic_card.dart';

class AddEditMedicationScreen extends ConsumerStatefulWidget {
  const AddEditMedicationScreen({this.medicationId, super.key});

  final int? medicationId;

  @override
  ConsumerState<AddEditMedicationScreen> createState() =>
      _AddEditMedicationScreenState();
}

class _AddEditMedicationScreenState
    extends ConsumerState<AddEditMedicationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();

  // State
  MedicationFrequency _frequency = MedicationFrequency.daily;
  List<TimeOfDay> _scheduledTimes = [const TimeOfDay(hour: 9, minute: 0)];
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  int _selectedColor = 0xFF4CAF50; // Default green
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMedication();
  }

  void _loadMedication() async {
    if (widget.medicationId == null) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(medicationRepositoryProvider);
      final medication = await repository.getById(widget.medicationId!);

      if (medication != null && mounted) {
        setState(() {
          _nameController.text = medication.name;
          _dosageController.text = medication.dosage;
          _frequency = medication.frequency;

          // Parse times from string format "HH:mm" to TimeOfDay
          _scheduledTimes = medication.times.map((timeStr) {
            final parts = timeStr.split(':');
            return TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          }).toList();

          _startDate = medication.startDate;
          _endDate = medication.endDate;
          _selectedColor = medication.color;
          _notesController.text = medication.notes ?? '';
          _isLoading = false;
        });
      } else if (mounted) {
        // Medication not found
        context.showErrorSnackbar(AppLocalizations.of(context).medicationNotFound);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackbar(AppLocalizations.of(context).errorLoadingMedication(e));
        context.pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onFrequencyChanged(MedicationFrequency? value) {
    if (value == null) return;
    setState(() {
      _frequency = value;
      _updateScheduledTimes();
    });
  }

  void _updateScheduledTimes() {
    var count = 1;
    switch (_frequency) {
      case MedicationFrequency.twiceDaily:
        count = 2;
        break;
      case MedicationFrequency.threeTimesDaily:
        count = 3;
        break;
      default:
        count = 1;
    }

    if (_scheduledTimes.length < count) {
      // Add times
      for (var i = _scheduledTimes.length; i < count; i++) {
        _scheduledTimes.add(const TimeOfDay(hour: 12, minute: 0));
      }
    } else if (_scheduledTimes.length > count) {
      // Remove times
      _scheduledTimes = _scheduledTimes.sublist(0, count);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final medication = Medication(
        id: widget.medicationId ?? 0, // 0 for new (auto-inc)
        name: _nameController.text,
        dosage: _dosageController.text,
        frequency: _frequency,
        times: _scheduledTimes.map((t) => '${t.hour}:${t.minute}').toList(),
        startDate: _startDate,
        endDate: _endDate,
        notes: _notesController.text,
        color: _selectedColor,
        isActive: true, // Default active
        syncStatus: SyncStatus.pending,
        lastModifiedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final notifier = ref.read(medicationProvider.notifier);
      if (widget.medicationId == null) {
        await notifier.addMedication(medication);
        if (mounted) {
          context.showSuccessSnackbar(AppLocalizations.of(context).medicationAddedSuccess);
        }
      } else {
        await notifier.updateMedication(medication);
        if (mounted) {
          context.showSuccessSnackbar(AppLocalizations.of(context).medicationUpdatedSuccess);
        }
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) context.showErrorSnackbar(AppLocalizations.of(context).errorSavingMedication(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassmorphicAppBar(
        title: widget.medicationId == null
            ? l10n.addMedication
            : l10n.editMedication,
      ),
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
        child: _isLoading && widget.medicationId != null
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Form(
                  key: _formKey,
                  child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Basic Info Card
                GlassmorphicCard(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: l10n.medicationName,
                          prefixIcon: const Icon(Icons.medication),
                          border: InputBorder.none,
                        ),
                        validator: (v) =>
                            v?.isEmpty == true ? l10n.requiredField : null,
                      ),
                      const Divider(),
                      TextFormField(
                        controller: _dosageController,
                        decoration: InputDecoration(
                          labelText: l10n.dosage,
                          prefixIcon: const Icon(Icons.scale),
                          border: InputBorder.none,
                        ),
                        validator: (v) =>
                            v?.isEmpty == true ? l10n.requiredField : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Frequency & Time
                GlassmorphicCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<MedicationFrequency>(
                        initialValue: _frequency,
                        decoration: InputDecoration(
                          labelText: l10n.frequency,
                          prefixIcon: const Icon(Icons.repeat),
                          border: InputBorder.none,
                        ),
                        items: MedicationFrequency.values.map((f) {
                          return DropdownMenuItem(
                            value: f,
                            child: Text(f.displayName),
                          );
                        }).toList(),
                        onChanged: _onFrequencyChanged,
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        l10n.scheduledTimes,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _scheduledTimes.asMap().entries.map((entry) {
                          final index = entry.key;
                          final time = entry.value;
                          return ActionChip(
                            avatar: const Icon(Icons.access_time, size: 16),
                            label: Text(time.format(context)),
                            onPressed: () async {
                              final newTime = await showTimePicker(
                                context: context,
                                initialTime: time,
                              );
                              if (newTime != null) {
                                setState(() {
                                  _scheduledTimes[index] = newTime;
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Color Picker
                GlassmorphicCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.color, style: theme.textTheme.titleSmall),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children:
                              [
                                0xFF4CAF50, // Green
                                0xFF2196F3, // Blue
                                0xFFE91E63, // Pink
                                0xFFFF9800, // Orange
                                0xFF9C27B0, // Purple
                                0xFFF44336, // Red
                                0xFF00BCD4, // Cyan
                                0xFF795548, // Brown
                              ].map((color) {
                                final isSelected = _selectedColor == color;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _selectedColor = color),
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Color(color),
                                        shape: BoxShape.circle,
                                        border: isSelected
                                            ? Border.all(
                                                color:
                                                    theme.colorScheme.primary,
                                                width: 3,
                                              )
                                            : null,
                                        boxShadow: [
                                          if (isSelected)
                                            BoxShadow(
                                              color: Color(
                                                color,
                                              ).withValues(alpha: 0.4),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                        ],
                                      ),
                                      child: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 20,
                                            )
                                          : null,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Save Button
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
                              strokeWidth: 2,
                              color: Colors.white,
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
      ),
    );
  }
}
