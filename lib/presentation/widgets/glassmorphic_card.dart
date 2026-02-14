/// VitalSync — Glassmorphic Card Widget.
///
/// Reusable glassmorphic card component with:
/// - BackdropFilter blur effect (sigma: 10)
/// - Semi-transparent background (theme-aware)
/// - Subtle border with opacity
/// - Custom shadow configuration
/// - WCAG AA contrast compliance
library;

import 'dart:ui';

import 'package:flutter/material.dart';

/// Reusable glassmorphic card widget with frosted glass effect.
///
/// Features:
/// - BackdropFilter blur for glassmorphism
/// - Theme-aware semi-transparent backgrounds
/// - Subtle borders with opacity
/// - Soft custom shadows
/// - Configurable padding and border radius
/// - WCAG AA contrast compliance
class GlassmorphicCard extends StatelessWidget {
  const GlassmorphicCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 20,
    this.border = true,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Glassmorphic background opacity
    final backgroundColor = isDark
        ? Colors.black.withValues(alpha: 0.15)
        : Colors.white.withValues(alpha: 0.7);

    // Border color with subtle opacity
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.1);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ? Border.all(color: borderColor, width: 1) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                spreadRadius: -5,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
