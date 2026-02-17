/// VitalSync — Splash Screen.
///
/// Initial loading screen shown on app launch.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/di/injection_container.dart';
import '../../core/gdpr/gdpr_manager.dart';

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

      // 2. Check GDPR consent
      final gdprManager = getIt<GDPRManager>();
      final hasGdprConsent = gdprManager.hasConsent(
        AppConstants.gdprConsentTypeAnalytics,
      );

      if (!hasGdprConsent) {
        // Navigate to GDPR consent screen
        if (mounted) context.go('/gdpr-consent');
        return;
      }

      // 3. Check authentication status
      final authRepo = getIt<FirebaseAuth>();
      final currentUser = authRepo.currentUser;

      if (!mounted) return;

      if (currentUser != null) {
        // User is authenticated, go to dashboard
        context.go('/dashboard');
      } else {
        // User is not authenticated, go to login
        context.go('/auth/login');
      }
    } catch (e) {
      // On error, default to login screen
      if (mounted) context.go('/auth/login');
    }
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
