/// VitalSync — Add Glucose Reading Screen.
///
/// Manual entry of a single blood glucose measurement.
///
/// No comment, only measurement: the form records the value, when it was
/// taken and an optional context label. It does not rate the value, compare
/// it to a range or say anything about what it means.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:vitalsync/core/enums/glucose_source.dart';
import 'package:vitalsync/core/enums/glucose_unit.dart';
import 'package:vitalsync/core/enums/meal_context.dart';
import 'package:vitalsync/core/enums/sync_status.dart';
import 'package:vitalsync/core/l10n/app_localizations.dart';
import 'package:vitalsync/core/theme/app_theme.dart';
import 'package:vitalsync/core/utils/extensions.dart';
import 'package:vitalsync/domain/entities/health/glucose_reading.dart';
import 'package:vitalsync/features/health/presentation/health_labels.dart';
import 'package:vitalsync/features/health/presentation/providers/glucose_provider.dart';
import 'package:vitalsync/presentation/widgets/glassmorphic_app_bar.dart';
import 'package:vitalsync/presentation/widgets/glassmorphic_card.dart';

class AddGlucoseReadingScreen extends ConsumerStatefulWidget {
  const AddGlucoseReadingScreen({super.key, this.initialMeasuredAt});

  /// Pre-fills the measurement date and time. Supplied by the post-meal
  /// reminder, which passes the moment it fired. Defaults to now.
  ///
  /// Only the time is pre-filled; the value is always the user's to enter.
  final DateTime? initialMeasuredAt;

  @override
  ConsumerState<AddGlucoseReadingScreen> createState() =>
      _AddGlucoseReadingScreenState();
}

class _AddGlucoseReadingScreenState
    extends ConsumerState<AddGlucoseReadingScreen> {
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();

  GlucoseUnit _unit = GlucoseUnit.mgPerDl;
  MealContext? _mealContext;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // A reminder can be tapped later than it fired, so the pre-filled moment
    // may be in the past — that is the point, and the picker allows it.
    final initial = widget.initialMeasuredAt ?? DateTime.now();
    _selectedDate = initial;
    _selectedTime = TimeOfDay.fromDateTime(initial);
  }

  @override
  void dispose() {
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);

    final raw = _valueController.text.trim();
    if (raw.isEmpty) {
      context.showErrorSnackbar(l10n.pleaseEnterGlucoseValue);
      return;
    }

    // Accept the comma decimal separator used by the tr and de locales.
    final parsed = double.tryParse(raw.replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) {
      context.showErrorSnackbar(l10n.invalidGlucoseValue);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final reading = GlucoseReading(
        id: 0, // auto-inc
        // Always stored in mg/dL, whatever unit the value was typed in.
        valueMgDl: _unit.toMgDl(parsed),
        measuredAt: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        ),
        source: GlucoseSource.manual,
        mealContext: _mealContext,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        syncStatus: SyncStatus.pending,
        lastModifiedAt: now,
        createdAt: now,
      );

      await ref.read(glucoseProvider.notifier).addReading(reading);

      if (mounted) {
        context.showSuccessSnackbar(l10n.glucoseLoggedSuccess);
        context.pop();
      }
    } catch (e) {
      // The value itself is never surfaced in the error — health data does
      // not go into log or crash-report strings.
      if (mounted) {
        context.showErrorSnackbar(
          AppLocalizations.of(context).errorLoggingGlucose(e),
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

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassmorphicAppBar(title: l10n.logGlucoseReading),
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
              // Value & unit
              GlassmorphicCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _valueController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9.,]'),
                        ),
                      ],
                      decoration: InputDecoration(
                        labelText: l10n.glucoseValue,
                        suffixText: _unit.label,
                        prefixIcon: const Icon(Icons.water_drop_outlined),
                        border: InputBorder.none,
                      ),
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(l10n.glucoseUnit, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    SegmentedButton<GlucoseUnit>(
                      segments: [
                        ButtonSegment(
                          value: GlucoseUnit.mgPerDl,
                          label: Text(l10n.glucoseUnitMgDl),
                        ),
                        ButtonSegment(
                          value: GlucoseUnit.mmolPerL,
                          label: Text(l10n.glucoseUnitMmolL),
                        ),
                      ],
                      selected: {_unit},
                      onSelectionChanged: (selection) =>
                          setState(() => _unit = selection.first),
                    ),
                  ],
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

              // Meal context — a descriptive label, optional and unranked.
              GlassmorphicCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.glucoseContext,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: MealContext.values.map((value) {
                        return ChoiceChip(
                          label: Text(value.label(l10n)),
                          selected: _mealContext == value,
                          onSelected: (selected) => setState(
                            () => _mealContext = selected ? value : null,
                          ),
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
