/// VitalSync — Quick Actions Card Widget.
///
/// Quick action buttons row (2x1):
/// - 4 buttons: Add Medication, Log Symptom, Start Workout, View Report
/// - Horizontal scroll with gradient backgrounds
/// - Module-specific colors and icons
/// - Tap ripple effects
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../glassmorphic_card.dart';

/// Quick actions card (2x1 grid size).
///
/// Features:
/// - 4 action buttons in horizontal scroll
/// - Module-specific gradient backgrounds
/// - Icon + label design
/// - Tap navigation to respective screens
class QuickActionsCard extends StatelessWidget {
  const QuickActionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return GlassmorphicCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _QuickActionButton(
            icon: Icons.medication,
            label: l10n.addMedication,
            gradient: AppTheme.healthGradient,
            onTap: () => context.push('/health/medication/add'),
          ),
          _QuickActionButton(
            icon: Icons.sick,
            label: l10n.logSymptom,
            gradient: AppTheme.healthGradient,
            onTap: () => context.push('/health/symptom/add'),
          ),
          _QuickActionButton(
            icon: Icons.fitness_center,
            label: l10n.startWorkout,
            gradient: AppTheme.fitnessGradient,
            onTap: () => context.push('/fitness/workout/start'),
          ),
          _QuickActionButton(
            icon: Icons.bar_chart,
            label: l10n.viewReport,
            gradient: AppTheme.insightGradient,
            onTap: () => context.push('/insights/weekly-report'),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
