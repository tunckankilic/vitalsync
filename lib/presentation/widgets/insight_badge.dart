/// VitalSync — Insight Badge Widget.
///
/// Badge showing unread insight count with animated pulse.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';

/// Insight badge widget with unread count.
///
/// Features:
/// - Displays unread insight count
/// - Animated pulse when new insights available
/// - Tappable to navigate to insights list
class InsightBadge extends ConsumerWidget {
  const InsightBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    // TODO: Replace with actual provider once it exists
    const unreadCount = 0; // ref.watch(unreadInsightsCountProvider)

    if (unreadCount == 0) {
      return const SizedBox.shrink();
    }

    return Semantics(
      label: l10n.insightsCountSemantics(unreadCount),
      button: true,
      child: _PulsingBadge(
        count: unreadCount,
        tooltip: l10n.insightsCountTooltip(unreadCount),
        onTap: () {
          // TODO: Navigate to insights list
          debugPrint('Navigate to insights');
        },
      ),
    );
  }
}

/// Pulsing badge animation for new insights.
class _PulsingBadge extends StatefulWidget {
  const _PulsingBadge({
    required this.count,
    required this.tooltip,
    required this.onTap,
  });

  final int count;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_PulsingBadge> createState() => _PulsingBadgeState();
}

class _PulsingBadgeState extends State<_PulsingBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: IconButton(
            icon: Badge(
              label: Text(
                widget.count > 9 ? '9+' : widget.count.toString(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: theme.colorScheme.tertiary,
              textColor: theme.colorScheme.onTertiary,
              child: Icon(
                Icons.lightbulb_rounded,
                color: theme.colorScheme.tertiary,
              ),
            ),
            onPressed: widget.onTap,
            tooltip: widget.tooltip,
          ),
        );
      },
    );
  }
}
