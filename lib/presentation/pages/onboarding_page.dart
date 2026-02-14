/// VitalSync — Onboarding Page.
///
/// First-time user onboarding experience.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Onboarding page widget.
///
/// Displays welcome screens and collects user preferences.
/// Will be fully implemented in Prompt 4.5.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.waving_hand_rounded,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome to VitalSync',
                style: theme.textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Your all-in-one health and fitness companion',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('Get Started'),
              ),
              const SizedBox(height: 16),
              Text(
                'Onboarding flow will be implemented in Prompt 4.5',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
