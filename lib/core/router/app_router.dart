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

import '../../features/fitness/presentation/screens/exercise_library_screen.dart';
import '../../features/health/presentation/screens/add_edit_medication_screen.dart';
import '../../features/health/presentation/screens/add_symptom_screen.dart';
import '../../features/health/presentation/screens/health_timeline_screen.dart';
import '../../features/health/presentation/screens/medication_detail_screen.dart';
import '../../features/health/presentation/screens/medication_list_screen.dart';
import '../../features/health/presentation/screens/symptom_list_screen.dart';
import '../../presentation/pages/dashboard_page.dart';
import '../../presentation/pages/onboarding_page.dart';
import '../../presentation/pages/splash_page.dart';
import '../../presentation/screens/app_shell.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/profile/edit_profile_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';

/// GoRouter configuration for VitalSync app navigation.
///
/// Features:
/// - Shell route for bottom navigation
/// - Nested navigation per tab
/// - Auth redirect logic
/// - Custom page transitions
// Define Keys
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
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

    // AUTH ROUTES
    GoRoute(
      path: '/auth',
      name: 'auth',
      redirect: (context, state) => '/auth/login',
      routes: [
        GoRoute(
          path: 'login',
          name: 'login',
          pageBuilder: (context, state) =>
              _buildPageWithFadeTransition(context, state, const LoginScreen()),
        ),
        GoRoute(
          path: 'register',
          name: 'register',
          pageBuilder: (context, state) => _buildPageWithFadeTransition(
            context,
            state,
            const RegisterScreen(),
          ),
        ),
        GoRoute(
          path: 'forgot-password',
          name: 'forgot_password',
          pageBuilder: (context, state) => _buildPageWithFadeTransition(
            context,
            state,
            const ForgotPasswordScreen(),
          ),
        ),
      ],
    ),

    // MAIN APP SHELL (Bottom Navigation with 3 tabs)
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
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
            const MedicationListScreen(),
          ),
          routes: [
            GoRoute(
              path: 'medications/:id',
              name: 'medication_detail',
              parentNavigatorKey: _rootNavigatorKey, // Hide bottom nav
              pageBuilder: (context, state) {
                final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                return _buildPageWithSlideTransition(
                  context,
                  state,
                  MedicationDetailScreen(medicationId: id),
                );
              },
            ),
            GoRoute(
              path: 'add-medication',
              name: 'add_medication',
              parentNavigatorKey: _rootNavigatorKey,
              pageBuilder: (context, state) => _buildPageWithSlideTransition(
                context,
                state,
                const AddEditMedicationScreen(),
              ),
            ),
            GoRoute(
              path: 'edit-medication',
              name: 'edit_medication',
              parentNavigatorKey: _rootNavigatorKey,
              pageBuilder: (context, state) {
                // expected ?id=... query param
                final id = int.tryParse(state.uri.queryParameters['id'] ?? '');
                return _buildPageWithSlideTransition(
                  context,
                  state,
                  AddEditMedicationScreen(medicationId: id),
                );
              },
            ),
            GoRoute(
              path: 'symptoms',
              name: 'symptoms',
              parentNavigatorKey: _rootNavigatorKey,
              pageBuilder: (context, state) => _buildPageWithSlideTransition(
                context,
                state,
                const SymptomListScreen(),
              ),
            ),
            GoRoute(
              path: 'add-symptom',
              name: 'add_symptom',
              parentNavigatorKey: _rootNavigatorKey,
              pageBuilder: (context, state) => _buildPageWithSlideTransition(
                context,
                state,
                const AddSymptomScreen(),
              ),
            ),
            GoRoute(
              path: 'timeline',
              name: 'timeline',
              parentNavigatorKey: _rootNavigatorKey,
              pageBuilder: (context, state) => _buildPageWithSlideTransition(
                context,
                state,
                const HealthTimelineScreen(),
              ),
            ),
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
          routes: [
            GoRoute(
              path: 'exercises',
              name: 'exercise_library',
              parentNavigatorKey: _rootNavigatorKey,
              pageBuilder: (context, state) {
                final isSelectionMode =
                    state.uri.queryParameters['selection'] == 'true';
                return _buildPageWithSlideTransition(
                  context,
                  state,
                  ExerciseLibraryScreen(isSelectionMode: isSelectionMode),
                );
              },
            ),
          ],
        ),
      ],
    ),

    // PROFILE & SETTINGS (Outside shell - full screen)
    GoRoute(
      path: '/profile',
      name: 'profile',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _buildPageWithSlideTransition(context, state, const ProfileScreen()),
      routes: [
        GoRoute(
          path: 'edit',
          name: 'edit_profile',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) => _buildPageWithSlideTransition(
            context,
            state,
            const EditProfileScreen(),
          ),
        ),
      ],
    ),
    // SETTINGS
    GoRoute(
      path: '/settings',
      name: 'settings',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _buildPageWithSlideTransition(context, state, const SettingsScreen()),
    ),
  ],
  // TODO: Add redirect logic for auth
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
