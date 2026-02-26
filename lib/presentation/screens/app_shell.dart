/// VitalSync — Main App Shell with Bottom Navigation.
///
/// Provides the main app structure with:
/// - Glassmorphic AppBar
/// - Bottom navigation (3 tabs: Dashboard, Health, Fitness)
/// - Context-aware FAB
/// - Nested navigation per tab
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/accessibility_helper.dart';
import '../../features/fitness/presentation/providers/workout_provider.dart';
import '../widgets/active_workout_mini_bar.dart';
import '../widgets/context_aware_fab.dart';
import '../widgets/glassmorphic_app_bar.dart';

/// Main app shell containing bottom navigation and app bar.
///
/// This widget wraps the main content and provides:
/// - Glassmorphic AppBar with dynamic title
/// - Bottom navigation bar with 3 tabs
/// - Context-aware FAB based on current tab
class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;
  bool _isFabVisible = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateCurrentIndexFromRoute();
  }

  /// Updates the current tab index based on the current route.
  void _updateCurrentIndexFromRoute() {
    final location = GoRouterState.of(context).uri.toString();
    final newIndex = _getIndexFromLocation(location);
    if (newIndex != _currentIndex) {
      setState(() => _currentIndex = newIndex);
    }
  }

  /// Gets the tab index from the current route location.
  int _getIndexFromLocation(String location) {
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/health')) return 1;
    if (location.startsWith('/fitness')) return 2;
    return 0; // Default to dashboard
  }

  bool _onScrollNotification(UserScrollNotification notification) {
    final direction = notification.direction;
    if (direction == ScrollDirection.reverse && _isFabVisible) {
      setState(() => _isFabVisible = false);
    } else if (direction == ScrollDirection.forward && !_isFabVisible) {
      setState(() => _isFabVisible = true);
    }
    return false;
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;

    setState(() => _currentIndex = index);

    // Navigate to the selected tab
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/health');
        break;
      case 2:
        context.go('/fitness');
        break;
    }
  }

  String _getAppBarTitle(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (_currentIndex) {
      case 0:
        return l10n.dashboard;
      case 1:
        return l10n.health;
      case 2:
        return l10n.fitness;
      default:
        return l10n.appTitle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // EXPERIMENTAL: Transparent background for glassmorphic effect
      // backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,

      // GLASSMORPHIC APP BAR
      appBar: GlassmorphicAppBar(
        title: _getAppBarTitle(context),
        onProfileTap: () => context.push('/profile'),
        onSettingsTap: () => context.push('/settings'),
      ),

      // BODY (Nested Navigator Content)
      body: NotificationListener<UserScrollNotification>(
        onNotification: _onScrollNotification,
        child: widget.child,
      ),

      // CONTEXT-AWARE FAB OR ACTIVE WORKOUT MINI-BAR
      floatingActionButton: ref
          .watch(activeSessionProvider)
          .when(
            data: (activeSession) {
              // If workout is active, show mini-bar instead of FAB
              if (activeSession != null) {
                return const ActiveWorkoutMiniBar();
              }

              // Otherwise show FAB with scroll-based visibility
              return AnimatedSlide(
                offset: _isFabVisible ? Offset.zero : const Offset(0, 2),
                duration: AccessibilityHelper.getDuration(
                  context,
                  const Duration(milliseconds: 200),
                ),
                curve: AccessibilityHelper.getCurve(context, Curves.easeInOut),
                child: AnimatedOpacity(
                  opacity: _isFabVisible ? 1.0 : 0.0,
                  duration: AccessibilityHelper.getDuration(
                    context,
                    const Duration(milliseconds: 200),
                  ),
                  child: ContextAwareFab(currentTabIndex: _currentIndex),
                ),
              );
            },
            loading: () => AnimatedSlide(
              offset: _isFabVisible ? Offset.zero : const Offset(0, 2),
              duration: AccessibilityHelper.getDuration(
                context,
                const Duration(milliseconds: 200),
              ),
              curve: AccessibilityHelper.getCurve(context, Curves.easeInOut),
              child: AnimatedOpacity(
                opacity: _isFabVisible ? 1.0 : 0.0,
                duration: AccessibilityHelper.getDuration(
                  context,
                  const Duration(milliseconds: 200),
                ),
                child: ContextAwareFab(currentTabIndex: _currentIndex),
              ),
            ),
            error: (_, _) => AnimatedSlide(
              offset: _isFabVisible ? Offset.zero : const Offset(0, 2),
              duration: AccessibilityHelper.getDuration(
                context,
                const Duration(milliseconds: 200),
              ),
              curve: AccessibilityHelper.getCurve(context, Curves.easeInOut),
              child: AnimatedOpacity(
                opacity: _isFabVisible ? 1.0 : 0.0,
                duration: AccessibilityHelper.getDuration(
                  context,
                  const Duration(milliseconds: 200),
                ),
                child: ContextAwareFab(currentTabIndex: _currentIndex),
              ),
            ),
          ),
      floatingActionButtonLocation: _currentIndex == 0
          ? FloatingActionButtonLocation.endFloat
          : FloatingActionButtonLocation.endFloat,

      // BOTTOM NAVIGATION BAR
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark
            ? theme.colorScheme.surface
            : theme.colorScheme.surface,
        selectedItemColor: AppTheme.healthPrimary,
        unselectedItemColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 8,
        items: [
          BottomNavigationBarItem(
            icon: Semantics(
              label: AppLocalizations.of(context).dashboardTabSemantics,
              button: true,
              child: const Icon(Icons.dashboard_rounded),
            ),
            activeIcon: Semantics(
              label: AppLocalizations.of(context).dashboardTabSelectedSemantics,
              button: true,
              child: const Icon(Icons.dashboard_rounded),
            ),
            label: AppLocalizations.of(context).dashboard,
            tooltip: AppLocalizations.of(context).dashboardTabTooltip,
          ),
          BottomNavigationBarItem(
            icon: Semantics(
              label: AppLocalizations.of(context).healthTabSemantics,
              button: true,
              child: const Icon(Icons.medical_services_rounded),
            ),
            activeIcon: Semantics(
              label: AppLocalizations.of(context).healthTabSelectedSemantics,
              button: true,
              child: const Icon(Icons.medical_services_rounded),
            ),
            label: AppLocalizations.of(context).health,
            tooltip: AppLocalizations.of(context).healthTabTooltip,
          ),
          BottomNavigationBarItem(
            icon: Semantics(
              label: AppLocalizations.of(context).fitnessTabSemantics,
              button: true,
              child: const Icon(Icons.fitness_center_rounded),
            ),
            activeIcon: Semantics(
              label: AppLocalizations.of(context).fitnessTabSelectedSemantics,
              button: true,
              child: const Icon(Icons.fitness_center_rounded),
            ),
            label: AppLocalizations.of(context).fitness,
            tooltip: AppLocalizations.of(context).fitnessTabTooltip,
          ),
        ],
      ),
    );
  }
}
