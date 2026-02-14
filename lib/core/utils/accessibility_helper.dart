/// VitalSync — Accessibility Helper Utilities.
///
/// Helper functions for accessibility features like reduce motion.
library;

import 'package:flutter/material.dart';

/// Accessibility helper class providing accessibility-related utilities.
///
/// Used to check and respect user accessibility preferences such as:
/// - Reduce motion
/// - High contrast
/// - Large text
class AccessibilityHelper {
  AccessibilityHelper._();

  /// Check if reduce motion is enabled.
  ///
  /// This reads the system accessibility setting for reduce motion.
  /// On iOS: Settings → Accessibility → Motion → Reduce Motion
  /// On Android: Settings → Accessibility → Remove animations
  ///
  /// When true, animations should be disabled or significantly reduced.
  static bool shouldReduceMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// Get appropriate animation duration based on reduce motion preference.
  ///
  /// Returns Duration.zero if reduce motion is enabled,
  /// otherwise returns the provided duration.
  ///
  /// Usage:
  /// ```dart
  /// AnimationController(
  ///   duration: AccessibilityHelper.getDuration(
  ///     context,
  ///     const Duration(milliseconds: 300),
  ///   ),
  ///   vsync: this,
  /// )
  /// ```
  static Duration getDuration(BuildContext context, Duration duration) {
    return shouldReduceMotion(context) ? Duration.zero : duration;
  }

  /// Get appropriate curve based on reduce motion preference.
  ///
  /// Returns Curves.linear if reduce motion is enabled,
  /// otherwise returns the provided curve.
  ///
  /// Usage:
  /// ```dart
  /// AnimatedContainer(
  ///   duration: const Duration(milliseconds: 300),
  ///   curve: AccessibilityHelper.getCurve(context, Curves.easeInOut),
  /// )
  /// ```
  static Curve getCurve(BuildContext context, Curve curve) {
    return shouldReduceMotion(context) ? Curves.linear : curve;
  }
}
