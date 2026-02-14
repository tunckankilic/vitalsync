import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vitalsync/core/theme/app_theme.dart';

class ContextualOnboardingCard extends ConsumerStatefulWidget {
  const ContextualOnboardingCard({super.key});

  @override
  ConsumerState<ContextualOnboardingCard> createState() =>
      _ContextualOnboardingCardState();
}

class _ContextualOnboardingCardState
    extends ConsumerState<ContextualOnboardingCard> {
  bool _isVisible = true;

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.healthPrimary.withValues(alpha: 0.15)
                  : AppTheme.healthPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.healthPrimary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.healthPrimary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.waving_hand_rounded,
                        color: AppTheme.healthPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Welcome to Health!', // Localize ideally
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () {
                        setState(() => _isVisible = false);
                        // TODO: Save to preferences
                      },
                      style: IconButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        backgroundColor: theme.colorScheme.surface.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "Let's get started by adding your first medication. tracking adherence helps you stay healthy!",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => context.push('/health/add-medication'),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add First Medication'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.healthPrimary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
