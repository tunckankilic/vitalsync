/// VitalSync — go_router Navigation Configuration.
///
/// Routes: splash, onboarding, auth, home (dashboard).
/// Health routes: medications, symptoms, timeline, health-settings.
/// Fitness routes: workouts, exercises, progress, calendar, achievements.
/// Insight routes: weekly-report, insight-detail.
/// Shared routes: profile, settings, gdpr-settings, data-export.
/// Auth redirect logic and nested navigation for bottom nav
/// (3 tabs: Dashboard, Health, Fitness).
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/pages/dashboard_page.dart';
import '../../presentation/pages/onboarding_page.dart';
import '../../presentation/pages/splash_page.dart';
import '../../presentation/screens/app_shell.dart';

/// GoRouter configuration for VitalSync app navigation.
///
/// Features:
/// - Shell route for bottom navigation
/// - Nested navigation per tab
/// - Auth redirect logic
/// - Custom page transitions
final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  debugLogDiagnostics: true,
  routes: [
    // SPLASH & ONBOARDING
    GoRoute(
      path: '/splash',
      name: 'splash',
      pageBuilder: (context, state) =>
          _buildPageWithFadeTransition(context, state, const SplashPage()),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      pageBuilder: (context, state) =>
          _buildPageWithFadeTransition(context, state, const OnboardingPage()),
    ),

    // MAIN APP SHELL (Bottom Navigation with 3 tabs)
    ShellRoute(
      builder: (context, state, child) {
        return AppShell(child: child);
      },
      routes: [
        // DASHBOARD TAB
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          pageBuilder: (context, state) => _buildPageWithFadeThroughTransition(
            context,
            state,
            const DashboardPage(),
          ),
        ),

        // HEALTH TAB
        GoRoute(
          path: '/health',
          name: 'health',
          pageBuilder: (context, state) => _buildPageWithFadeThroughTransition(
            context,
            state,
            const Placeholder(), // TODO: Create HealthPage
          ),
          routes: const [
            // Health nested routes will be added
          ],
        ),

        // FITNESS TAB
        GoRoute(
          path: '/fitness',
          name: 'fitness',
          pageBuilder: (context, state) => _buildPageWithFadeThroughTransition(
            context,
            state,
            const Placeholder(), // TODO: Create FitnessPage
          ),
          routes: const [
            // Fitness nested routes will be added
          ],
        ),
      ],
    ),

    // PROFILE & SETTINGS (Outside shell - full screen)
    GoRoute(
      path: '/profile',
      name: 'profile',
      pageBuilder: (context, state) => _buildPageWithSlideTransition(
        context,
        state,
        const Placeholder(), // TODO: Create ProfilePage
      ),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      pageBuilder: (context, state) => _buildPageWithSlideTransition(
        context,
        state,
        const Placeholder(), // TODO: Create SettingsPage
      ),
    ),
  ],
  // TODO: Add redirect logic for auth in later prompts
  // redirect: (context, state) { ... }
);

// PAGE TRANSITION BUILDERS

/// Fade through transition for tab switches (Material Design 3 spec).
Page _buildPageWithFadeThroughTransition(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Fade through: current page fades out, new page fades in
      const begin = 0.0;
      const end = 1.0;
      const curve = Curves.easeInOut;

      final tween = Tween(
        begin: begin,
        end: end,
      ).chain(CurveTween(curve: curve));

      return FadeTransition(opacity: animation.drive(tween), child: child);
    },
  );
}

/// Fade transition for splash/onboarding.
Page _buildPageWithFadeTransition(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

/// Slide transition for profile/settings.
Page _buildPageWithSlideTransition(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0); // Slide from right
      const end = Offset.zero;
      const curve = Curves.easeInOutCubic;

      final tween = Tween(
        begin: begin,
        end: end,
      ).chain(CurveTween(curve: curve));

      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}
