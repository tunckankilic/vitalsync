/// VitalSync — Splash Screen.
///
/// Initial loading screen shown on app launch.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Splash screen widget.
///
/// Displays app logo and handles initial navigation logic.
/// Checks for:
/// - First launch (navigate to onboarding)
/// - Authentication status (navigate to login or dashboard)
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Simulate loading time
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // TODO: Check first launch and auth status
    // For now, always navigate to dashboard
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Icon/Logo
            Icon(
              Icons.favorite_rounded,
              size: 100,
              color: theme.colorScheme.onPrimary,
            ),
            const SizedBox(height: 24),

            // App Name
            Text(
              'VitalSync',
              style: theme.textTheme.headlineLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Tagline
            Text(
              'Health & Fitness Companion',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 48),

            // Loading indicator
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.onPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
