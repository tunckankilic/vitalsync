/// VitalSync — Splash Screen.
///
/// Initial loading screen shown on app launch.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/di/injection_container.dart';
import '../../domain/repositories/shared/auth_repository.dart';
import '../../main.dart' show appInitError;

/// Splash screen widget.
///
/// Displays app logo and handles initial navigation logic.
/// Checks for:
/// - First launch (navigate to onboarding)
/// - GDPR consent (navigate to GDPR screen if not consented)
/// - Authentication status (navigate to login or dashboard)
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Simulate loading time for smooth UX
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Check for critical initialization errors
    if (appInitError != null) {
      if (!mounted) return;
      _showInitErrorDialog(appInitError!);
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Check if this is first launch
      final isFirstLaunch = prefs.getBool(AppConstants.keyFirstLaunch) ?? true;
      if (isFirstLaunch) {
        // Mark as not first launch anymore
        await prefs.setBool(AppConstants.keyFirstLaunch, false);
        if (mounted) context.go('/onboarding');
        return;
      }

      // 2. Check authentication first.
      //
      // An already-signed-in user always goes straight to the dashboard.
      // Gating onboarding ahead of this check would trap an authenticated user
      // on the onboarding flow whenever the onboarding-completed flag is unset
      // (e.g. they signed in before the flag was ever written).
      final authRepo = getIt<AuthRepository>();
      final isAuthenticated = authRepo.currentUser != null;

      if (isAuthenticated) {
        if (mounted) context.go('/dashboard');
        return;
      }

      // 3. Not signed in — make sure onboarding has been completed before
      // showing login. Onboarding is where GDPR consent is collected AND
      // persisted (via GDPRManager). We gate on the onboarding-completed flag
      // rather than on a single optional consent (e.g. analytics): the
      // standalone /gdpr-consent route has no exit affordance, and gating on an
      // optional consent would loop the user back here forever if they declined
      // it. Funnel anyone who hasn't finished onboarding through that flow.
      final onboardingCompleted =
          prefs.getBool(AppConstants.prefKeyOnboardingCompleted) ?? false;

      if (!mounted) return;

      if (onboardingCompleted) {
        context.go('/auth/login');
      } else {
        context.go('/onboarding');
      }
    } catch (e) {
      // On error, default to login screen
      if (mounted) context.go('/auth/login');
    }
  }

  void _showInitErrorDialog(Object error) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Initialization Error'),
        content: Text(
          'The app could not start properly. Please check your internet '
          'connection and try again.\n\nDetails: $error',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/auth/login');
            },
            child: const Text('Continue Anyway'),
          ),
        ],
      ),
    );
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
              'VitalSynch',
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
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
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
