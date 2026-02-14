/// VitalSync — PR Badge Component
///
/// Animated badge for displaying personal record achievements.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// An animated badge that displays when a personal record is achieved.
class PRBadge extends StatelessWidget {
  /// Creates a PR badge.
  const PRBadge({this.size = 24, this.animate = true, super.key});

  /// Size of the badge.
  final double size;

  /// Whether to animate the badge.
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: size * 0.4,
        vertical: size * 0.2,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.3),
            blurRadius: size * 0.4,
            spreadRadius: size * 0.1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events, size: size, color: Colors.white),
          SizedBox(width: size * 0.2),
          Text(
            'NEW PR!',
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.6,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );

    if (!animate) {
      return badge;
    }

    return badge
        .animate()
        .scale(
          duration: const Duration(milliseconds: 300),
          curve: Curves.elasticOut,
        )
        .shimmer(
          duration: const Duration(milliseconds: 1000),
          color: Colors.white.withValues(alpha: 0.5),
        );
  }
}

/// A gold flash overlay effect for PR achievements.
class GoldFlashOverlay extends StatefulWidget {
  /// Creates a gold flash overlay.
  const GoldFlashOverlay({required this.child, required this.show, super.key});

  /// The widget to overlay.
  final Widget child;

  /// Whether to show the flash effect.
  final bool show;

  @override
  State<GoldFlashOverlay> createState() => _GoldFlashOverlayState();
}

class _GoldFlashOverlayState extends State<GoldFlashOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(GoldFlashOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.show)
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFFFD700,
                    ).withOpacity(0.3 * (1 - _animation.value)),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
