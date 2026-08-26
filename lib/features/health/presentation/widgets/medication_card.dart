import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/enums/medication_log_status.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../domain/entities/health/medication.dart';
import '../../../../domain/entities/health/medication_log.dart';
import '../../../../presentation/widgets/glassmorphic_card.dart';
import '../health_labels.dart';
import '../providers/medication_log_provider.dart';

/// Resolves a medication's effective status for *today* from the day's logs.
///
/// A taken log wins over a skipped one; with neither the dose is still pending.
MedicationLogStatus _todayStatusFor(List<MedicationLog> logs, int medicationId) {
  final medLogs = logs.where((l) => l.medicationId == medicationId);
  if (medLogs.any((l) => l.status == MedicationLogStatus.taken)) {
    return MedicationLogStatus.taken;
  }
  if (medLogs.any((l) => l.status == MedicationLogStatus.skipped)) {
    return MedicationLogStatus.skipped;
  }
  return MedicationLogStatus.pending;
}

class MedicationCard extends ConsumerWidget {
  const MedicationCard({required this.medication, super.key});

  final Medication medication;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // Watch compliance rate for this medication
    final complianceAsync = ref.watch(complianceRateProvider(medication.id));

    // Today's logged status drives the reactive UI: once a dose is taken or
    // skipped the card shows a status badge and swiping is disabled.
    final todayLogs = ref.watch(todayLogsProvider).asData?.value ?? const [];
    final todayStatus = _todayStatusFor(todayLogs, medication.id);

    return SlidableMedicationCard(
      medication: medication,
      status: todayStatus,
      child: GlassmorphicCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Color Indicator Strip
                Container(
                  width: 6,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Color(medication.color),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: Color(medication.color).withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Main Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${medication.dosage} • ${medication.frequency.label(l10n)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Compliance & Next Time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Next dose time (simplified logic)
                    _NextDoseBadge(medication: medication),
                    const SizedBox(height: 8),
                    // Mini compliance ring
                    _ComplianceRing(
                      compliance: complianceAsync.asData?.value ?? 0.0,
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Quick Actions (or status badge once logged for today)
            Align(
              alignment: Alignment.centerRight,
              child: _QuickActions(medication: medication, status: todayStatus),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextDoseBadge extends StatelessWidget {
  const _NextDoseBadge({required this.medication});

  final Medication medication;

  @override
  Widget build(BuildContext context) {
    // Logic to find next scheduled time would go here
    // For now, simpler display based on 'times' list
    final nextTime = medication.times.firstOrNull ?? '09:00';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time_rounded,
            size: 12,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            nextTime,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComplianceRing extends StatelessWidget {
  const _ComplianceRing({required this.compliance});

  final double compliance;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              value: compliance,
              strokeWidth: 4,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              color: _getColorForCompliance(compliance),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${(compliance * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForCompliance(double value) {
    if (value >= 0.9) return Colors.green;
    if (value >= 0.7) return Colors.amber;
    return Colors.red;
  }
}

class _QuickActions extends ConsumerWidget {
  const _QuickActions({required this.medication, required this.status});

  final Medication medication;
  final MedicationLogStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    // Once the dose is logged for today, replace the buttons with a status
    // badge so the action reads as completed and can't be double-logged.
    if (status == MedicationLogStatus.taken) {
      return _StatusBadge(
        label: l10n.taken,
        icon: Icons.check_circle_rounded,
        color: AppTheme.healthPrimary,
      );
    }
    if (status == MedicationLogStatus.skipped) {
      return _StatusBadge(
        label: l10n.skipped,
        icon: Icons.cancel_rounded,
        color: Colors.grey,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(
          label: l10n.skip,
          icon: Icons.close_rounded,
          color: Colors.grey,
          onTap: () {
            ref
                .read(logMedicationProvider.notifier)
                .logAsSkipped(medication.id, DateTime.now());
          },
        ),
        const SizedBox(width: 8),
        _ActionButton(
          label: l10n.take,
          icon: Icons.check_rounded,
          color: AppTheme.healthPrimary,
          onTap: () {
            ref
                .read(logMedicationProvider.notifier)
                .logAsTaken(medication.id, DateTime.now());
          },
        ),
      ],
    );
  }
}

/// Read-only badge shown after a dose has been taken or skipped for the day.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SlidableMedicationCard extends ConsumerWidget {
  const SlidableMedicationCard({
    required this.child,
    required this.medication,
    required this.status,
    super.key,
  });

  final Widget child;
  final Medication medication;
  final MedicationLogStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final tappable = InkWell(
      onTap: () => context.push('/health/medications/${medication.id}'),
      child: child,
    );

    // Already logged for today: no swipe action left to take, so just show the
    // card (its badge already conveys the taken/skipped state).
    if (status != MedicationLogStatus.pending) {
      return tappable;
    }

    // Swipe right → take (complete), swipe left → skip. Both fire the action and
    // return false so the card stays in the tree; the reactive status badge
    // (driven by todayLogsProvider) handles the visual transition.
    return Dismissible(
      key: ValueKey('med-swipe-${medication.id}'),
      direction: DismissDirection.horizontal,
      background: _SwipeBackground(
        alignment: Alignment.centerLeft,
        color: AppTheme.healthPrimary,
        icon: Icons.check_circle_rounded,
        label: l10n.take,
      ),
      secondaryBackground: _SwipeBackground(
        alignment: Alignment.centerRight,
        color: Colors.orange,
        icon: Icons.cancel_rounded,
        label: l10n.skip,
      ),
      confirmDismiss: (direction) async {
        final notifier = ref.read(logMedicationProvider.notifier);
        if (direction == DismissDirection.startToEnd) {
          await notifier.logAsTaken(medication.id, DateTime.now());
        } else {
          await notifier.logAsSkipped(medication.id, DateTime.now());
        }
        // Keep the card; todayLogsProvider rebuilds it into the logged state.
        return false;
      },
      child: tappable,
    );
  }
}

/// Coloured background revealed while swiping a medication card.
class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isLeft = alignment == Alignment.centerLeft;
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLeft) ...[
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (!isLeft) ...[
            const SizedBox(width: 8),
            Icon(icon, color: Colors.white),
          ],
        ],
      ),
    );
  }
}
