/// VitalSync — Rest Timer Widget
///
/// Circular countdown timer with color transitions and haptic feedback.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A circular countdown timer for rest periods between sets.
///
/// Features:
/// - Color transitions based on remaining time
/// - Haptic feedback at 3, 2, 1 seconds
/// - Skip button
/// - Completion callback
class RestTimerWidget extends StatefulWidget {
  /// Creates a rest timer.
  const RestTimerWidget({
    required this.durationSeconds,
    required this.onComplete,
    this.onSkip,
    super.key,
  });

  /// Total duration in seconds.
  final int durationSeconds;

  /// Callback when timer completes.
  final VoidCallback onComplete;

  /// Optional callback when timer is skipped.
  final VoidCallback? onSkip;

  @override
  State<RestTimerWidget> createState() => _RestTimerWidgetState();
}

class _RestTimerWidgetState extends State<RestTimerWidget> {
  late int _remainingSeconds;
  Timer? _timer;
  bool _hasVibrated3 = false;
  bool _hasVibrated2 = false;
  bool _hasVibrated1 = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.durationSeconds;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });

        // Haptic feedback at 3, 2, 1
        _triggerHapticIfNeeded();
      } else {
        timer.cancel();
        _triggerCompletionHaptic();
        widget.onComplete();
      }
    });
  }

  Future<void> _triggerHapticIfNeeded() async {
    if (_remainingSeconds == 3 && !_hasVibrated3) {
      _hasVibrated3 = true;
      await HapticFeedback.mediumImpact();
    } else if (_remainingSeconds == 2 && !_hasVibrated2) {
      _hasVibrated2 = true;
      await HapticFeedback.mediumImpact();
    } else if (_remainingSeconds == 1 && !_hasVibrated1) {
      _hasVibrated1 = true;
      await HapticFeedback.heavyImpact();
    }
  }

  Future<void> _triggerCompletionHaptic() async {
    await HapticFeedback.lightImpact();
  }

  void _handleSkip() {
    _timer?.cancel();
    widget.onSkip?.call();
  }

  Color _getTimerColor() {
    final progress = _remainingSeconds / widget.durationSeconds;
    if (progress > 0.5) {
      return Colors.green;
    } else if (progress > 0.25) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _remainingSeconds / widget.durationSeconds;
    final timerColor = _getTimerColor();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Circular timer
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 8,
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              // Progress circle
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
                color: timerColor,
              ),
              // Time text
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _remainingSeconds.toString(),
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
                  ),
                  Text('seconds', style: theme.textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Skip button
        TextButton(onPressed: _handleSkip, child: const Text('Skip Rest')),
      ],
    );
  }
}
