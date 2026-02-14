/// VitalSync — Glassmorphic Card Component
///
/// Reusable glassmorphic container with WCAG AA contrast compliance.
library;

import 'dart:ui';
import 'package:flutter/material.dart';

/// A glassmorphic card widget with blur effect and semi-transparent background.
///
/// Provides a modern, frosted glass appearance while maintaining WCAG AA
/// contrast requirements for accessibility.
class GlassmorphicCard extends StatelessWidget {
  /// Creates a glassmorphic card.
  const GlassmorphicCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 16,
    this.blur = 10,
    this.opacity = 0.1,
    this.border = true,
    this.gradient,
    super.key,
  });

  /// The widget to display inside the card.
  final Widget child;

  /// Padding around the child widget.
  final EdgeInsets padding;

  /// Border radius of the card.
  final double borderRadius;

  /// Blur intensity for the backdrop filter.
  final double blur;

  /// Opacity of the background color.
  final double opacity;

  /// Whether to show a border around the card.
  final bool border;

  /// Optional gradient overlay.
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // WCAG AA compliant colors
    final backgroundColor = isDark
        ? Colors.white.withValues(alpha: opacity)
        : Colors.black.withValues(alpha: opacity);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.black.withValues(alpha: 0.1);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            gradient: gradient,
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ? Border.all(color: borderColor, width: 1) : null,
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

/// A glassmorphic card with a color accent strip on the left.
class GlassmorphicCardWithStrip extends StatelessWidget {
  /// Creates a glassmorphic card with a color strip.
  const GlassmorphicCardWithStrip({
    required this.child,
    required this.stripColor,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 16,
    this.stripWidth = 4,
    super.key,
  });

  /// The widget to display inside the card.
  final Widget child;

  /// Color of the accent strip.
  final Color stripColor;

  /// Padding around the child widget.
  final EdgeInsets padding;

  /// Border radius of the card.
  final double borderRadius;

  /// Width of the color strip.
  final double stripWidth;

  @override
  Widget build(BuildContext context) {
    return GlassmorphicCard(
      padding: EdgeInsets.zero,
      borderRadius: borderRadius,
      child: Row(
        children: [
          Container(
            width: stripWidth,
            decoration: BoxDecoration(
              color: stripColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(borderRadius),
                bottomLeft: Radius.circular(borderRadius),
              ),
            ),
          ),
          Expanded(
            child: Padding(padding: padding, child: child),
          ),
        ],
      ),
    );
  }
}
