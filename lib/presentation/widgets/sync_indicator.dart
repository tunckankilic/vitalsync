/// VitalSync — Sync Status Indicator Widget.
///
/// Shows current sync state with animations:
/// - Online: Green pulse
/// - Offline: Gray static
/// - Syncing: Rotating arrows
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/sync/sync_provider.dart';

/// Sync status indicator widget.
///
/// Displays current sync status with appropriate icon and animation:
/// - Online: Green pulse animation
/// - Offline: Gray static icon
/// - Syncing: Rotating arrows animation
class SyncIndicator extends ConsumerWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    // Watch connectivity and sync status
    final connectivityAsync = ref.watch(connectivityProvider);
    final syncStatus = ref.watch(syncStatusProvider);

    // Determine states from providers
    final isOnline = connectivityAsync.when(
      data: (isConnected) => isConnected,
      loading: () => false,
      error: (_, _) => false,
    );

    final isSyncing = syncStatus == SyncStatus.syncing;
    final hasError = syncStatus == SyncStatus.error;

    // Dynamic semantics and tooltip based on state
    final semanticsLabel = hasError
        ? 'Sync error' // TODO: Add l10n.syncSemanticsError when available
        : isSyncing
        ? l10n.syncSemanticsSyncing
        : isOnline
        ? l10n.syncSemanticsOnline
        : l10n.syncSemanticsOffline;

    final tooltip = hasError
        ? 'Sync error - tap to retry' // TODO: Add l10n.syncErrorTooltip when available
        : isSyncing
        ? l10n.syncingTooltip
        : isOnline
        ? l10n.syncOnlineTooltip
        : l10n.syncOfflineTooltip;

    return Semantics(
      label: semanticsLabel,
      child: IconButton(
        icon: _buildSyncIcon(
          context,
          isOnline: isOnline,
          isSyncing: isSyncing,
          hasError: hasError,
        ),
        onPressed: null, // Non-interactive, just an indicator
        tooltip: tooltip,
      ),
    );
  }

  Widget _buildSyncIcon(
    BuildContext context, {
    required bool isOnline,
    required bool isSyncing,
    required bool hasError,
  }) {
    if (hasError) {
      // Red error icon for sync error
      return const Icon(
        Icons.sync_problem_rounded,
        color: Colors.red,
        size: 20,
      );
    }

    if (isSyncing) {
      // Rotating arrows for syncing state
      return const _RotatingIcon(icon: Icons.sync_rounded, color: Colors.blue);
    }

    if (isOnline) {
      // Pulsing green dot for online
      return const _PulsingIcon(
        icon: Icons.cloud_done_rounded,
        color: Colors.green,
      );
    }

    // Gray cloud off for offline
    return const Icon(Icons.cloud_off_rounded, color: Colors.grey, size: 20);
  }
}

/// Rotating icon animation for syncing state.
class _RotatingIcon extends StatefulWidget {
  const _RotatingIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  State<_RotatingIcon> createState() => _RotatingIconState();
}

class _RotatingIconState extends State<_RotatingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * 3.14159, // Full rotation
          child: Icon(widget.icon, color: widget.color, size: 20),
        );
      },
    );
  }
}

/// Pulsing icon animation for online state.
class _PulsingIcon extends StatefulWidget {
  const _PulsingIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Icon(widget.icon, color: widget.color, size: 20),
        );
      },
    );
  }
}
