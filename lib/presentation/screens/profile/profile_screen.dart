import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitalsync/core/auth/auth_provider.dart';
import 'package:vitalsync/core/settings/settings_provider.dart';
// import 'package:vitalsync/core/constants/app_constants.dart'; // Loop if needed, but avoiding for now

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final unitSystem = ref.watch(unitSystemSettingProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Background - slightly different from others
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFE0F2F1),
                  Color(0xFFFAFAFA),
                ], // Light Teal to White
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
                      final name = user?.name ?? 'User';
                      final authState = ref.watch(authStateProvider);
                      final email = authState.value?.email ?? 'No email';
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
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                              ),
                              child: const Icon(
                                Icons.person,
                                size: 64,
                                color: Colors.grey,
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
                          Text(email, style: TextStyle(color: Colors.grey[600]))
                              .animate()
                              .fadeIn(delay: 100.ms)
                              .moveY(begin: 10, end: 0),
                        ],
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Text('Error loading profile: $err'),
                  ),

                  const SizedBox(height: 32),

                  // Stats Overview Card (Glassmorphic)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
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
                        const _StatItem(
                          label: 'Workouts',
                          value: '12',
                          icon: Icons.fitness_center,
                          color: Colors.blueAccent,
                        ),
                        _VerticalDivider(),
                        const _StatItem(
                          label: 'Streak',
                          value: '5',
                          icon: Icons.local_fire_department,
                          color: Colors.orange,
                        ),
                        _VerticalDivider(),
                        const _StatItem(
                          label: 'Health',
                          value: '85%',
                          icon: Icons.favorite,
                          color: Colors.redAccent,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 32),

                  // Unit System Toggle
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.8),
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
                            const Text(
                              'Unit System',
                              style: TextStyle(
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
                                const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Text(
                                      'kg',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'lbs',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
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
                                            ? 'kg'
                                            : 'lbs',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
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
                      // Edit Profile Logic
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Profile'),
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
                    onPressed: () {
                      ref.read(authProvider.notifier).signOut();
                      // Go router redirect should handle this, or:
                      // context.go('/auth/login');
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Log Out'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(height: 40, width: 1, color: Colors.grey[300]);
  }
}
