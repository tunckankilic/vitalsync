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

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/fitness/presentation/screens/achievements_screen.dart';
import '../../features/fitness/presentation/screens/calendar_screen.dart';
import '../../features/fitness/presentation/screens/exercise_library_screen.dart';
import '../../features/fitness/presentation/screens/progress_screen.dart';
import '../../features/fitness/presentation/screens/workout_home_screen.dart';
import '../../features/fitness/presentation/screens/workout_summary_screen.dart';
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
import '../../presentation/screens/gdpr/consent_screen.dart';
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

    // GDPR CONSENT
    GoRoute(
      path: '/gdpr-consent',
      name: 'gdpr_consent',
      pageBuilder: (context, state) =>
          _buildPageWithFadeTransition(context, state, const ConsentScreen()),
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
            const WorkoutHomeScreen(),
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
            GoRoute(
              path: 'workout-summary/:sessionId',
              name: 'workout_summary',
              parentNavigatorKey: _rootNavigatorKey,
              pageBuilder: (context, state) {
                final sessionId = int.parse(state.pathParameters['sessionId']!);
                return _buildPageWithSlideUpTransition(
                  context,
                  state,
                  WorkoutSummaryScreen(sessionId: sessionId),
                );
              },
            ),
            GoRoute(
              path: 'progress',
              name: 'progress',
              parentNavigatorKey: _rootNavigatorKey,
              pageBuilder: (context, state) => _buildPageWithSlideTransition(
                context,
                state,
                const ProgressScreen(),
              ),
            ),
            GoRoute(
              path: 'achievements',
              name: 'achievements',
              parentNavigatorKey: _rootNavigatorKey,
              pageBuilder: (context, state) => _buildPageWithSlideTransition(
                context,
                state,
                const AchievementsScreen(),
              ),
            ),
            GoRoute(
              path: 'calendar',
              name: 'calendar',
              parentNavigatorKey: _rootNavigatorKey,
              pageBuilder: (context, state) => _buildPageWithSlideTransition(
                context,
                state,
                const CalendarScreen(),
              ),
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
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;
    final currentPath = state.uri.path;

    // Public routes that don't require authentication
    const publicRoutes = [
      '/splash',
      '/onboarding',
      '/gdpr-consent',
      '/auth/login',
      '/auth/register',
      '/auth/forgot-password',
    ];

    // Check if current route is public
    final isPublicRoute = publicRoutes.any(currentPath.startsWith);

    // If user is not logged in and trying to access protected route
    if (!isLoggedIn && !isPublicRoute) {
      return '/auth/login';
    }

    // If user is logged in and trying to access auth pages, redirect to dashboard
    if (isLoggedIn && currentPath.startsWith('/auth')) {
      return '/dashboard';
    }

    // No redirect needed
    return null;
  },
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

/// Slide up transition for modal-style screens (e.g., workout summary).
Page _buildPageWithSlideUpTransition(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0); // Slide from bottom
      const end = Offset.zero;
      const curve = Curves.easeOutCubic;

      final tween = Tween(
        begin: begin,
        end: end,
      ).chain(CurveTween(curve: curve));

      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}
