/// VitalSync — Context-Aware FAB Component.
///
/// FAB that changes based on current tab:
/// - Dashboard: Expandable quick-add menu (fan-out)
/// - Health: Single "Add Medication" button
/// - Fitness: Single "Start Workout" button
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/accessibility_helper.dart';

/// Context-aware floating action button.
///
/// Changes functionality based on the currently active tab:
/// - Tab 0 (Dashboard): Quick add menu with fan-out mini FABs
/// - Tab 1 (Health): Single FAB for adding medication
/// - Tab 2 (Fitness): Single FAB for starting workout
class ContextAwareFab extends ConsumerStatefulWidget {
  const ContextAwareFab({required this.currentTabIndex, super.key});

  final int currentTabIndex;

  @override
  ConsumerState<ContextAwareFab> createState() => _ContextAwareFabState();
}

class _ContextAwareFabState extends ConsumerState<ContextAwareFab>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update duration based on reduce motion
    _animationController.duration = AccessibilityHelper.getDuration(
      context,
      const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _onAddMedication() {
    if (_isExpanded) _toggleExpanded();
    context.push('/health/add-medication');
  }

  void _onLogSymptom() {
    if (_isExpanded) _toggleExpanded();
    context.push('/health/add-symptom');
  }

  void _onStartWorkout() {
    if (_isExpanded) _toggleExpanded();
    context.push('/fitness/exercises');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // Dashboard tab: Expandable menu
    if (widget.currentTabIndex == 0) {
      return Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          // Mini FAB 1: Add Medication (Health)
          _buildMiniFab(
            context,
            offset: const Offset(0, -140),
            icon: Icons.medication_rounded,
            label: l10n.addMedication,
            color: AppTheme.healthPrimary,
            onPressed: _onAddMedication,
          ),

          // Mini FAB 2: Log Symptom (Health)
          _buildMiniFab(
            context,
            offset: const Offset(0, -90),
            icon: Icons.healing_rounded,
            label: l10n.logSymptom,
            color: AppTheme.healthSecondary,
            onPressed: _onLogSymptom,
          ),

          // Mini FAB 3: Start Workout (Fitness)
          _buildMiniFab(
            context,
            offset: const Offset(0, -40),
            icon: Icons.fitness_center_rounded,
            label: l10n.startWorkout,
            color: AppTheme.fitnessPrimary,
            onPressed: _onStartWorkout,
          ),

          // Main FAB
          FloatingActionButton(
            onPressed: _toggleExpanded,
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            child: Semantics(
              label: _isExpanded
                  ? l10n.quickAddMenuClose
                  : l10n.quickAddMenuOpen,
              button: true,
              child: AnimatedRotation(
                turns: _isExpanded ? 0.125 : 0, // 45 degrees when expanded
                duration: AccessibilityHelper.getDuration(
                  context,
                  const Duration(milliseconds: 200),
                ),
                child: const Icon(Icons.add_rounded),
              ),
            ),
          ),
        ],
      );
    }

    // Health tab: Single FAB for adding medication
    if (widget.currentTabIndex == 1) {
      final l10n = AppLocalizations.of(context);
      return FloatingActionButton.extended(
        onPressed: _onAddMedication,
        backgroundColor: AppTheme.healthPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.medication_rounded),
        label: Text(l10n.addMedication),
      );
    }

    // Fitness tab: Single FAB for starting workout
    if (widget.currentTabIndex == 2) {
      final l10n = AppLocalizations.of(context);
      return FloatingActionButton.extended(
        onPressed: _onStartWorkout,
        backgroundColor: AppTheme.fitnessPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.fitness_center_rounded),
        label: Text(l10n.startWorkout),
      );
    }

    // Default: No FAB
    return const SizedBox.shrink();
  }

  Widget _buildMiniFab(
    BuildContext context, {
    required Offset offset,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        final animatedOffset = Offset(
          offset.dx * _expandAnimation.value,
          offset.dy * _expandAnimation.value,
        );

        return Transform.translate(
          offset: animatedOffset,
          child: Opacity(
            opacity: _expandAnimation.value,
            child: _expandAnimation.value > 0 ? child : const SizedBox.shrink(),
          ),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label
          Material(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Mini FAB
          Semantics(
            label: label,
            button: true,
            child: FloatingActionButton.small(
              onPressed: onPressed,
              backgroundColor: color,
              foregroundColor: Colors.white,
              heroTag: label, // Unique tag for each mini FAB
              child: Icon(icon, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
