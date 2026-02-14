import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Providers for consent state
class AnalyticsConsentNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void update(bool value) => state = value;
}

final analyticsConsentProvider =
    NotifierProvider<AnalyticsConsentNotifier, bool>(
      AnalyticsConsentNotifier.new,
    );

class HealthDataConsentNotifier extends Notifier<bool> {
  @override
  bool build() => true;
  void update(bool value) => state = value;
}

final healthDataConsentProvider =
    NotifierProvider<HealthDataConsentNotifier, bool>(
      HealthDataConsentNotifier.new,
    );

class FitnessDataConsentNotifier extends Notifier<bool> {
  @override
  bool build() => true;
  void update(bool value) => state = value;
}

final fitnessDataConsentProvider =
    NotifierProvider<FitnessDataConsentNotifier, bool>(
      FitnessDataConsentNotifier.new,
    );

class CloudBackupConsentNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void update(bool value) => state = value;
}

final cloudBackupConsentProvider =
    NotifierProvider<CloudBackupConsentNotifier, bool>(
      CloudBackupConsentNotifier.new,
    );

class ConsentScreen extends StatelessWidget {
  const ConsentScreen({super.key, this.isOnboarding = false});
  final bool isOnboarding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Data'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(child: ConsentContent(isOnboarding: isOnboarding)),
    );
  }
}

class ConsentContent extends ConsumerWidget {
  const ConsentContent({super.key, required this.isOnboarding});
  final bool isOnboarding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read state
    final analyticsConsent = ref.watch(analyticsConsentProvider);
    final healthConsent = ref.watch(healthDataConsentProvider);
    final fitnessConsent = ref.watch(fitnessDataConsentProvider);
    final cloudConsent = ref.watch(cloudBackupConsentProvider);

    // Form logic: Check if required consents are given
    final canProceed = healthConsent && fitnessConsent;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isOnboarding) ...[
            const Icon(Icons.shield_outlined, size: 48, color: Colors.indigo),
            const SizedBox(height: 16),
            Text(
              'Your Privacy Matters',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ).animate().fadeIn().moveY(begin: 10, end: 0),
            const SizedBox(height: 8),
            Text(
              'We believe in transparency. Please review and manage how your data is handled.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),
          ],

          Expanded(
            child: ListView(
              children: [
                _ConsentCard(
                  title: 'Health Data Processing',
                  description:
                      'Required to track medications and symptoms locally.',
                  isRequired: true,
                  value: healthConsent,
                  onChanged: (val) {
                    if (!val) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'This is required for the Health module to function.',
                          ),
                        ),
                      );
                      return;
                    }
                    ref.read(healthDataConsentProvider.notifier).update(val);
                  },
                  icon: Icons.medical_services_outlined,
                ),
                _ConsentCard(
                  title: 'Fitness Data Processing',
                  description:
                      'Required to log workouts and track progress locally.',
                  isRequired: true,
                  value: fitnessConsent,
                  onChanged: (val) {
                    if (!val) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'This is required for the Fitness module to function.',
                          ),
                        ),
                      );
                      return;
                    }
                    ref.read(fitnessDataConsentProvider.notifier).update(val);
                  },
                  icon: Icons.fitness_center_outlined,
                ),
                _ConsentCard(
                  title: 'Analytics & Usage',
                  description:
                      'Help us improve VitalSync by sharing anonymous usage data.',
                  isRequired: false,
                  value: analyticsConsent,
                  onChanged: (val) =>
                      ref.read(analyticsConsentProvider.notifier).update(val),
                  icon: Icons.analytics_outlined,
                ),
                _ConsentCard(
                  title: 'Cloud Backup',
                  description:
                      "Securely backup your data to the cloud so you don't lose it.",
                  isRequired: false,
                  value: cloudConsent,
                  onChanged: (val) =>
                      ref.read(cloudBackupConsentProvider.notifier).update(val),
                  icon: Icons.cloud_upload_outlined,
                ),

                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () {
                      // Open Privacy Policy
                    },
                    child: const Text('Read Full Privacy Policy'),
                  ),
                ),
              ],
            ),
          ),

          if (isOnboarding)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canProceed
                    ? () {
                        // Save consents and navigate
                        context.go('/auth/login');
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Accept & Continue'),
              ),
            ),
        ],
      ),
    );
  }
}

class _ConsentCard extends StatelessWidget {
  const _ConsentCard({
    required this.title,
    required this.description,
    required this.isRequired,
    required this.value,
    required this.onChanged,
    required this.icon,
  });
  final String title;
  final String description;
  final bool isRequired;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      color: Colors.white.withValues(alpha: 0.8), // Glass-ish
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (isRequired)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.redAccent.withValues(alpha: 0.5),
                            ),
                          ),
                          child: const Text(
                            'REQUIRED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: isRequired && value ? onChanged : onChanged,
              activeThumbColor: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
