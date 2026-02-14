import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vitalsync/core/l10n/app_localizations.dart';
import 'package:vitalsync/presentation/screens/gdpr/consent_screen.dart'; // Will be created later

final onboardingStepProvider = NotifierProvider<OnboardingStepNotifier, int>(
  OnboardingStepNotifier.new,
);

class OnboardingStepNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setStep(int step) {
    state = step;
  }
}

final selectedInterestsProvider =
    NotifierProvider<SelectedInterestsNotifier, List<String>>(
      SelectedInterestsNotifier.new,
    );

class SelectedInterestsNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  void toggle(String interest) {
    if (state.contains(interest)) {
      state = [...state]..remove(interest);
    } else {
      state = [...state, interest];
    }
  }
}

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  static const _totalSteps = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStep = ref.watch(onboardingStepProvider);
    final pageController = PageController(initialPage: currentStep);
    final l10n = AppLocalizations.of(context);

    // Sync page controller with provider if needed, or just use provider for UI state
    // For simplicity, we'll drive the PageView with the controller and update provider on change.

    return Scaffold(
      body: Stack(
        children: [
          // Background - can be a subtle gradient or image
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE0F7FA),
                  Color(0xFFF3E5F5),
                ], // Light Cyan to Light Purple
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Row(
                    children: List.generate(_totalSteps, (index) {
                      return Expanded(
                        child:
                            Container(
                                  height: 4,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: index <= currentStep
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                )
                                .animate(target: index <= currentStep ? 1 : 0)
                                .color(
                                  begin: Colors.grey.withValues(alpha: 0.3),
                                  end: Theme.of(context).primaryColor,
                                  duration: 300.ms,
                                ),
                      );
                    }),
                  ),
                ),

                Expanded(
                  child: PageView(
                    controller: pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      ref.read(onboardingStepProvider.notifier).setStep(index);
                    },
                    children: const [
                      _WelcomePage(),
                      _PersonalizationPage(),
                      _QuickSetupPage(),
                      ConsentContent(isOnboarding: true),
                    ],
                  ),
                ),

                // Bottom Navigation
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (currentStep > 0)
                        TextButton(
                          onPressed: () {
                            pageController.previousPage(
                              duration: 300.ms,
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Text(l10n.back),
                        )
                      else
                        const SizedBox(width: 64), // Spacer
                      // Skip button for optional steps (1 and 2)
                      if (currentStep == 1 || currentStep == 2)
                        TextButton(
                          onPressed: () {
                            pageController.nextPage(
                              duration: 300.ms,
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Text(l10n.skip),
                        ),

                      ElevatedButton(
                        onPressed: () {
                          if (currentStep < _totalSteps - 1) {
                            pageController.nextPage(
                              duration: 300.ms,
                              curve: Curves.easeInOut,
                            );
                          } else {
                            // Finish onboarding
                            context.go(
                              '/auth/login',
                            ); // Or dashboard depending on auth state
                            // Ideally, check auth state via provider
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          currentStep == _totalSteps - 1
                              ? l10n.getStarted
                              : l10n.next,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
                Icons.health_and_safety,
                size: 80,
                color: Colors.blueAccent,
              )
              .animate()
              .scale(duration: 600.ms, curve: Curves.elasticOut)
              .then()
              .shimmer(duration: 1200.ms),
          const SizedBox(height: 32),
          Text(
            l10n.welcomeTitle,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ).animate().fadeIn(delay: 200.ms).moveY(begin: 20, end: 0),
          const SizedBox(height: 16),
          Text(
            l10n.welcomeSubtitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[700]),
          ).animate().fadeIn(delay: 400.ms).moveY(begin: 20, end: 0),
          const SizedBox(height: 48),
          // Language Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: 'EN',
                items: const [
                  DropdownMenuItem(value: 'EN', child: Text('English')),
                  DropdownMenuItem(value: 'TR', child: Text('Türkçe')),
                  DropdownMenuItem(value: 'DE', child: Text('Deutsch')),
                ],
                onChanged: (val) {
                  // TODO: Implement localization change
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonalizationPage extends ConsumerWidget {
  const _PersonalizationPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedInterests = ref.watch(selectedInterestsProvider);
    final l10n = AppLocalizations.of(context);

    void toggleInterest(String interest) {
      ref.read(selectedInterestsProvider.notifier).toggle(interest);
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n.personalizationTitle,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ).animate().fadeIn().moveX(begin: -20, end: 0),
          const SizedBox(height: 24),
          _InterestCard(
            title: l10n.interestMedication,
            icon: Icons.medication,
            color: Colors.redAccent,
            isSelected: selectedInterests.contains('medication'),
            onTap: () => toggleInterest('medication'),
          ),
          const SizedBox(height: 16),
          _InterestCard(
            title: l10n.interestFitness,
            icon: Icons.fitness_center,
            color: Colors.blueAccent,
            isSelected: selectedInterests.contains('fitness'),
            onTap: () => toggleInterest('fitness'),
          ),
          const SizedBox(height: 16),
          _InterestCard(
            title: l10n.interestInsights,
            icon: Icons.lightbulb,
            color: Colors.amber,
            isSelected: selectedInterests.contains('insights'),
            onTap: () => toggleInterest('insights'),
          ),
          const SizedBox(height: 16),
          _InterestCard(
            title: l10n.interestAnalysis,
            icon: Icons.bar_chart,
            color: Colors.green,
            isSelected: selectedInterests.contains('analysis'),
            onTap: () => toggleInterest('analysis'),
          ),
        ],
      ),
    );
  }
}

class _InterestCard extends StatelessWidget {
  const _InterestCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });
  final String title;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 300.ms,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 10,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
              ).animate().scale(duration: 200.ms),
          ],
        ),
      ),
    );
  }
}

class _QuickSetupPage extends StatelessWidget {
  const _QuickSetupPage();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n.quickSetupTitle,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.quickSetupSubtitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 48),

          // Add Medication Option
          _QuickActionCard(
            title: l10n.quickAddMedication,
            subtitle: l10n.quickAddMedicationSubtitle,
            icon: Icons.medication_liquid,
            color: Colors.redAccent,
            onTap: () {
              // Open simple dialog or navigate
            },
          ),
          const SizedBox(height: 16),

          // Select Template Option
          _QuickActionCard(
            title: l10n.quickPickTemplate,
            subtitle: l10n.quickPickTemplateSubtitle,
            icon: Icons.fitness_center_outlined,
            color: Colors.blueAccent,
            onTap: () {
              // Open selection
            },
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
