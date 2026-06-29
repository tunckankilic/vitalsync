import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vitalsync/core/auth/auth_provider.dart';
import 'package:vitalsync/core/l10n/app_localizations.dart';
import 'package:vitalsync/core/settings/settings_provider.dart';
import 'package:vitalsync/features/fitness/presentation/providers/streak_provider.dart';
import 'package:vitalsync/features/fitness/presentation/providers/workout_provider.dart';
import 'package:vitalsync/features/health/presentation/providers/medication_log_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final unitSystem = ref.watch(unitSystemSettingProvider);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      // Transparent app bar purely for the automatic back button — this screen
      // is pushed on the root navigator, so without an app bar there was no way
      // back. extendBodyBehindAppBar keeps the gradient flush to the top.
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: colorScheme.onSurface,
      ),
      body: Stack(
        children: [
          // Background — adapts to the active theme so the profile no longer
          // renders light in dark mode.
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [const Color(0xFF06302A), colorScheme.surface]
                    : const [Color(0xFFE0F2F1), Color(0xFFFAFAFA)],
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Profile Header
                  userAsync.when(
                    data: (user) {
                      final authUser = ref.watch(authStateProvider).value;
                      // Prefer a locally-edited name, then the identity name
                      // from Cognito (Apple / email sign-up). This screen used
                      // to read only the local DB, so Apple users — who have no
                      // local profile until they edit one — always showed "User"
                      // even when Cognito had their name.
                      final localName = user?.name.trim() ?? '';
                      final cognitoName = authUser?.displayName?.trim() ?? '';
                      final name = localName.isNotEmpty
                          ? localName
                          : (cognitoName.isNotEmpty
                                ? cognitoName
                                : l10n.defaultUser);
                      final email = authUser?.email ?? l10n.noEmail;
                      // final photoUrl = user?.photoUrl;

                      return Column(
                        children: [
                          Hero(
                            tag: 'profile-avatar',
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colorScheme.surfaceContainerHighest,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                                border: Border.all(
                                  color: colorScheme.surface,
                                  width: 4,
                                ),
                              ),
                              child: Icon(
                                Icons.person,
                                size: 64,
                                color: colorScheme.onSurfaceVariant,
                              ), // Replace with NetworkImage if available
                            ),
                          ).animate().scale(
                            duration: 500.ms,
                            curve: Curves.easeOutBack,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            name,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ).animate().fadeIn().moveY(begin: 10, end: 0),
                          Text(
                            email,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 100.ms)
                              .moveY(begin: 10, end: 0),
                        ],
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Text(l10n.errorLoadingProfile(err)),
                  ),

                  const SizedBox(height: 32),

                  // Stats Overview Card (Glassmorphic)
                  const _ProfileStats(),

                  const SizedBox(height: 32),

                  // Unit System Toggle
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(
                        alpha: isDark ? 0.4 : 0.6,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.teal.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.scale,
                                color: Colors.teal,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              l10n.unitSystem,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        // Custom Animated Toggle
                        GestureDetector(
                          onTap: () {
                            final newSystem = unitSystem == UnitSystem.metric
                                ? UnitSystem.imperial
                                : UnitSystem.metric;
                            ref
                                .read(unitSystemSettingProvider.notifier)
                                .setUnitSystem(newSystem);
                          },
                          child: AnimatedContainer(
                            duration: 300.ms,
                            width: 100,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Stack(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Text(
                                      l10n.kg,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        // Track is always a light grey, so the
                                        // hint labels use a fixed dark tone
                                        // rather than the theme's onSurface.
                                        color: Colors.black45,
                                      ),
                                    ),
                                    Text(
                                      l10n.lbs,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black45,
                                      ),
                                    ),
                                  ],
                                ),
                                AnimatedAlign(
                                  duration: 300.ms,
                                  curve: Curves.easeInOut,
                                  alignment: unitSystem == UnitSystem.metric
                                      ? Alignment.centerLeft
                                      : Alignment.centerRight,
                                  child: Container(
                                    width: 46,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.1,
                                          ),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        unitSystem == UnitSystem.metric
                                            ? l10n.kg
                                            : l10n.lbs,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          // Thumb is always white.
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  ElevatedButton.icon(
                    onPressed: () {
                      // push (not go): go rewrites the history stack, which left
                      // /profile as the stack root on return, so its AppBar back
                      // button (canPop == false) vanished. push keeps the stack
                      // intact — edit pops cleanly back to a still-poppable profile.
                      context.push('/profile/edit');
                    },
                    icon: const Icon(Icons.edit),
                    label: Text(l10n.editProfile),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () => _confirmAndSignOut(context, ref, l10n),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: Text(l10n.logOut),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Confirms, then signs out. The auth-state stream drives the GoRouter
  /// redirect back to /auth/login, so no manual navigation is needed. The
  /// messenger is captured before the await so an error can still be surfaced
  /// after the widget is torn down.
  Future<void> _confirmAndSignOut(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.logOutConfirmTitle),
        content: Text(l10n.logOutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.logOut),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(authProvider.notifier).signOut();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorGeneric(e))));
    }
  }
}

class _ProfileStats extends ConsumerWidget {
  const _ProfileStats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Watch providers
    final workoutCountAsync = ref.watch(totalWorkoutCountProvider);
    final streakAsync = ref.watch(currentStreakProvider);
    final complianceAsync = ref.watch(overallComplianceProvider);

    // Helper to format values
    String formatValue<T>(
      AsyncValue<T> asyncValue,
      String Function(T) formatter,
    ) {
      return asyncValue.when(
        data: (value) => formatter(value),
        loading: () => '...',
        error: (_, _) => '-',
      );
    }

    final workouts = formatValue<int>(workoutCountAsync, (v) => v.toString());
    final streak = formatValue<int>(streakAsync, (v) => v.toString());
    final health = formatValue<double>(
      complianceAsync,
      (v) => '${(v * 100).toInt()}%',
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: isDark ? 0.4 : 0.7),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            label: l10n.workouts,
            value: workouts,
            icon: Icons.fitness_center,
            color: Colors.blueAccent,
          ),
          _VerticalDivider(),
          _StatItem(
            label: l10n.streak,
            value: streak,
            icon: Icons.local_fire_department,
            color: Colors.orange,
          ),
          _VerticalDivider(),
          _StatItem(
            label: l10n.health,
            value: health,
            icon: Icons.favorite,
            color: Colors.redAccent,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 1,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}
