/// VitalSync — Glassmorphic AppBar Component.
///
/// Frosted glass effect AppBar with:
/// - BackdropFilter blur effect
/// - Semi-transparent background
/// - Dynamic title with animated transitions
/// - Profile avatar, settings icon, insight badge, sync indicator
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/utils/accessibility_helper.dart';
import '../widgets/insight_badge.dart';
import '../widgets/sync_indicator.dart';

/// Custom AppBar with glassmorphic effect.
///
/// Features:
/// - Frosted glass blur effect with BackdropFilter
/// - Semi-transparent background
/// - Animated title transitions
/// - Action buttons: profile, settings, insight badge, sync indicator
class GlassmorphicAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const GlassmorphicAppBar({
    required this.title,
    this.onProfileTap,
    this.onSettingsTap,
    this.actions,
    super.key,
  });

  final String title;
  final VoidCallback? onProfileTap;
  final VoidCallback? onSettingsTap;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Glassmorphic background opacity
    final backgroundColor = isDark
        ? Colors.black.withValues(alpha: 0.15)
        : Colors.white.withValues(alpha: 0.7);

    // Border color with subtle opacity
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.1);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border(bottom: BorderSide(color: borderColor, width: 1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                spreadRadius: -5,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AppBar(
            title: AnimatedSwitcher(
              duration: AccessibilityHelper.getDuration(
                context,
                const Duration(milliseconds: 200),
              ),
              transitionBuilder: (child, animation) {
                // Skip transition animation if reduce motion is enabled
                if (AccessibilityHelper.shouldReduceMotion(context)) {
                  return child;
                }

                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.2),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Text(
                title,
                key: ValueKey<String>(title),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
            foregroundColor: theme.colorScheme.onSurface,
            actions: [
              // Sync Indicator
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: SyncIndicator(),
              ),

              // Insight Badge
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: InsightBadge(),
              ),

              // Actions
              if (actions != null) ...actions!,

              const SizedBox(width: 8),

              // Profile Icon
              if (onProfileTap != null)
                IconButton(
                  icon: const Icon(Icons.person_rounded),
                  onPressed: onProfileTap,
                ),
              // Settings Icon
              if (onSettingsTap != null)
                IconButton(
                  icon: const Icon(Icons.settings_rounded),
                  onPressed: onSettingsTap,
                  tooltip: AppLocalizations.of(context).settingsTooltip,
                ),
              Semantics(
                label: AppLocalizations.of(context).profileSemantics,
                button: true,
                child: Hero(
                  tag: 'profile_avatar',
                  child: GestureDetector(
                    onTap: onProfileTap,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        Icons.person,
                        size: 20,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
