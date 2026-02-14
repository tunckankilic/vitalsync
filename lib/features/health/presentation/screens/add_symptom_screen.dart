import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:vitalsync/core/enums/sync_status.dart';
import 'package:vitalsync/core/l10n/app_localizations.dart';
import 'package:vitalsync/core/theme/app_theme.dart';
import 'package:vitalsync/core/utils/extensions.dart';
import 'package:vitalsync/domain/entities/health/symptom.dart';
import 'package:vitalsync/features/health/presentation/providers/symptom_provider.dart';
import 'package:vitalsync/presentation/widgets/glassmorphic_app_bar.dart';
import 'package:vitalsync/presentation/widgets/glassmorphic_card.dart';

class AddSymptomScreen extends ConsumerStatefulWidget {
  const AddSymptomScreen({super.key});

  @override
  ConsumerState<AddSymptomScreen> createState() => _AddSymptomScreenState();
}

class _AddSymptomScreenState extends ConsumerState<AddSymptomScreen> {
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  int _severity = 1;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  final List<String> _selectedTags = [];
  bool _isLoading = false;

  final List<String> _commonSymptoms = [
    'Headache',
    'Nausea',
    'Fatigue',
    'Dizziness',
    'Stomach Pain',
    'Back Pain',
    'Joint Pain',
    'Insomnia',
    'Anxiety',
    'Shortness of Breath',
  ]; // Ideally localized

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty) {
      context.showErrorSnackbar('Please enter a symptom name');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final symptom = Symptom(
        id: 0, // auto-inc
        name: _nameController.text,
        severity: _severity,
        date: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        ),
        notes: _notesController.text,
        tags: _selectedTags,
        syncStatus: SyncStatus.pending,
        lastModifiedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await ref.read(symptomProvider.notifier).addSymptom(symptom);

      if (mounted) {
        context.showSuccessSnackbar('Symptom logged successfully');
        context.pop();
      }
    } catch (e) {
      if (mounted) context.showErrorSnackbar('Error logging symptom: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // Need localized common symptoms in real app

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassmorphicAppBar(title: l10n.logSymptom),
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
              // Name Input & Suggestions
              GlassmorphicCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: l10n.symptomName,
                        prefixIcon: const Icon(Icons.healing),
                        border: InputBorder.none,
                      ),
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _commonSymptoms.take(6).map((symptom) {
                        return ActionChip(
                          label: Text(symptom),
                          onPressed: () {
                            _nameController.text = symptom;
                          },
                          backgroundColor: theme
                              .colorScheme
                              .surfaceContainerHigh
                              .withValues(alpha: 0.5),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Severity Slider
              GlassmorphicCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.severity, style: theme.textTheme.titleSmall),
                        Text(
                          _getSeverityLabel(_severity),
                          style: TextStyle(
                            color: _getSeverityColor(_severity),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: _getSeverityColor(_severity),
                        thumbColor: _getSeverityColor(_severity),
                        overlayColor: _getSeverityColor(
                          _severity,
                        ).withValues(alpha: 0.2),
                      ),
                      child: Slider(
                        value: _severity.toDouble(),
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: _severity.toString(),
                        onChanged: (val) =>
                            setState(() => _severity = val.toInt()),
                      ),
                    ),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Mild', style: TextStyle(fontSize: 10)),
                        Text('Unbearable', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Date & Time
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

  String _getSeverityLabel(int severity) {
    switch (severity) {
      case 1:
        return '😊 Mild';
      case 2:
        return '😐 Moderate';
      case 3:
        return '😟 Severe';
      case 4:
        return '😣 Very Severe';
      case 5:
        return '😫 Unbearable';
      default:
        return '';
    }
  }

  Color _getSeverityColor(int severity) {
    switch (severity) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.amber;
      case 4:
        return Colors.orange;
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
