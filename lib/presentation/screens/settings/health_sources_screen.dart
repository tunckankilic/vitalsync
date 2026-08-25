/// VitalSync — Health Sources Screen.
///
/// Apple Health connection state, last import time and the connect /
/// import / disconnect actions.
///
/// Read-only by design: VitalSync never asks for write access to the health
/// store, and this screen states that plainly.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vitalsync/core/health/health_import_service.dart';
import 'package:vitalsync/core/l10n/app_localizations.dart';
import 'package:vitalsync/core/utils/extensions.dart';
import 'package:vitalsync/features/health/presentation/providers/health_source_provider.dart';

class HealthSourcesScreen extends ConsumerStatefulWidget {
  const HealthSourcesScreen({super.key});

  @override
  ConsumerState<HealthSourcesScreen> createState() =>
      _HealthSourcesScreenState();
}

class _HealthSourcesScreenState extends ConsumerState<HealthSourcesScreen> {
  bool _isBusy = false;

  /// Runs one health-source action, surfacing the outcome as a snackbar.
  ///
  /// [onSuccess] builds the message from the result; only counts reach it,
  /// never an imported value. [onError] lets each action name its own
  /// failure — a declined permission is not an import failure.
  Future<void> _run<T>(
    Future<T> Function() action,
    String Function(T result, AppLocalizations l10n) onSuccess,
    String Function(Object error, AppLocalizations l10n) onError,
  ) async {
    setState(() => _isBusy = true);
    try {
      final result = await action();
      if (mounted) {
        context.showSuccessSnackbar(
          onSuccess(result, AppLocalizations.of(context)),
        );
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackbar(onError(e, AppLocalizations.of(context)));
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final statusAsync = ref.watch(healthSourceStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.healthSources),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: statusAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(l10n.errorGeneric(err))),
        data: (status) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.favorite_rounded,
                      color: status.isAuthorized
                          ? theme.colorScheme.primary
                          : theme.disabledColor,
                    ),
                    title: Text(l10n.appleHealth),
                    subtitle: Text(
                      status.isAuthorized
                          ? l10n.healthSourceConnected
                          : l10n.healthSourceNotConnected,
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.schedule_rounded),
                    title: Text(l10n.healthSourceLastImport),
                    subtitle: Text(
                      status.lastImportAt == null
                          ? l10n.healthSourceNeverImported
                          : status.lastImportAt!.format('MMM d, yyyy HH:mm'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (status.isAuthorized) ...[
              FilledButton.icon(
                onPressed: _isBusy ? null : _importNow,
                icon: const Icon(Icons.download_rounded),
                label: Text(l10n.healthSourceImportNow),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _isBusy ? null : _disconnect,
                icon: const Icon(Icons.link_off_rounded),
                label: Text(l10n.healthSourceDisconnect),
              ),
            ] else
              FilledButton.icon(
                onPressed: _isBusy ? null : _connect,
                icon: const Icon(Icons.link_rounded),
                label: Text(l10n.healthSourceConnect),
              ),

            const SizedBox(height: 24),

            // The read-only guarantee, stated where the user grants access.
            Card(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.healthSourceReadOnlyNotice,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              l10n.healthSourceTypesTitle,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  _TypeRow(
                    icon: Icons.water_drop_outlined,
                    label: l10n.healthSourceTypeGlucose,
                  ),
                  _TypeRow(
                    icon: Icons.directions_walk_rounded,
                    label: l10n.healthSourceTypeSteps,
                  ),
                  _TypeRow(
                    icon: Icons.local_fire_department_rounded,
                    label: l10n.healthSourceTypeActiveEnergy,
                  ),
                  _TypeRow(
                    icon: Icons.fitness_center_rounded,
                    label: l10n.healthSourceTypeWorkouts,
                  ),
                  _TypeRow(
                    icon: Icons.bedtime_rounded,
                    label: l10n.healthSourceTypeSleep,
                    isLast: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _connect() {
    return _run(
      () => ref.read(healthSourceProvider.notifier).connect(),
      _importedMessage,
      (error, l10n) => l10n.healthSourceImportFailed(error),
    );
  }

  Future<void> _importNow() {
    return _run(
      () => ref.read(healthSourceProvider.notifier).importNow(),
      _importedMessage,
      (error, l10n) => l10n.healthSourceImportFailed(error),
    );
  }

  Future<void> _disconnect() {
    return _run(
      () => ref.read(healthSourceProvider.notifier).disconnect(),
      (_, l10n) => l10n.healthSourceDisconnected,
      (error, l10n) => l10n.errorGeneric(error),
    );
  }

  /// Counts only — the imported values themselves are never shown here.
  String _importedMessage(HealthImportResult result, AppLocalizations l10n) {
    return result.totalImported == 0
        ? l10n.healthSourceNothingNew
        : l10n.healthSourceImported(result.totalImported);
  }
}

class _TypeRow extends StatelessWidget {
  const _TypeRow({
    required this.icon,
    required this.label,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, size: 20),
          title: Text(label),
          dense: true,
        ),
        if (!isLast) const Divider(height: 1),
      ],
    );
  }
}
