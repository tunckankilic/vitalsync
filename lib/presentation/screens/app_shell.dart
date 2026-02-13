/// VitalSync — Main App Shell with Bottom Navigation.
///
/// Provides the main app structure with:
/// - Glassmorphic AppBar
/// - Bottom navigation (3 tabs: Dashboard, Health, Fitness)
/// - Context-aware FAB
/// - Nested navigation per tab
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
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
  final ScrollController _scrollController = ScrollController();
  bool _isFabVisible = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Hide FAB when scrolling down, show when scrolling up
    if (_scrollController.hasClients) {
      final isScrollingDown =
          _scrollController.position.userScrollDirection ==
          ScrollDirection.reverse;

      if (isScrollingDown && _isFabVisible) {
        setState(() => _isFabVisible = false);
      } else if (!isScrollingDown && !_isFabVisible) {
        setState(() => _isFabVisible = true);
      }
    }
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

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Health';
      case 2:
        return 'Fitness';
      default:
        return 'VitalSync';
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
        title: _getAppBarTitle(),
        onProfileTap: () => context.push('/profile'),
        onSettingsTap: () => context.push('/settings'),
      ),

      // BODY (Nested Navigator Content)
      body: widget.child,

      // CONTEXT-AWARE FAB
      floatingActionButton: AnimatedSlide(
        offset: _isFabVisible ? Offset.zero : const Offset(0, 2),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: AnimatedOpacity(
          opacity: _isFabVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: ContextAwareFab(currentTabIndex: _currentIndex),
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
              label: 'Dashboard tab',
              button: true,
              child: const Icon(Icons.dashboard_rounded),
            ),
            activeIcon: Semantics(
              label: 'Dashboard tab, selected',
              button: true,
              child: const Icon(Icons.dashboard_rounded),
            ),
            label: 'Dashboard',
            tooltip: 'View your unified health and fitness dashboard',
          ),
          BottomNavigationBarItem(
            icon: Semantics(
              label: 'Health tab',
              button: true,
              child: const Icon(Icons.medical_services_rounded),
            ),
            activeIcon: Semantics(
              label: 'Health tab, selected',
              button: true,
              child: const Icon(Icons.medical_services_rounded),
            ),
            label: 'Health',
            tooltip: 'Manage medications and symptoms',
          ),
          BottomNavigationBarItem(
            icon: Semantics(
              label: 'Fitness tab',
              button: true,
              child: const Icon(Icons.fitness_center_rounded),
            ),
            activeIcon: Semantics(
              label: 'Fitness tab, selected',
              button: true,
              child: const Icon(Icons.fitness_center_rounded),
            ),
            label: 'Fitness',
            tooltip: 'Track workouts and progress',
          ),
        ],
      ),
    );
  }
}
