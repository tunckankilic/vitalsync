/// VitalSync — Onboarding Page.
///
/// First-time user onboarding experience with:
/// - Welcome screen
/// - Feature introduction (Health, Fitness, Insights)
/// - GDPR consent
/// - User preferences (locale, theme, unit system)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/di/injection_container.dart';
import '../../core/gdpr/gdpr_manager.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/settings/settings_provider.dart';

/// Onboarding page with multi-step flow.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // GDPR consent states
  bool _analyticsConsent = false;
  bool _healthDataConsent = true; // Required for core functionality
  bool _fitnessDataConsent = true; // Required for core functionality
  bool _cloudBackupConsent = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.animateToPage(
        _currentPage - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    // Save GDPR consents
    final gdprManager = getIt<GDPRManager>();

    if (_analyticsConsent) {
      await gdprManager.grantConsent(AppConstants.gdprConsentTypeAnalytics);
    }
    if (_healthDataConsent) {
      await gdprManager.grantConsent(AppConstants.gdprConsentTypeHealthData);
    }
    if (_fitnessDataConsent) {
      await gdprManager.grantConsent(AppConstants.gdprConsentTypeFitnessData);
    }
    if (_cloudBackupConsent) {
      await gdprManager.grantConsent(AppConstants.gdprConsentTypeCloudBackup);
    }

    // Mark onboarding as completed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefKeyOnboardingCompleted, true);

    if (!mounted) return;

    // Navigate to login screen
    context.go('/auth/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: LinearProgressIndicator(
                value: (_currentPage + 1) / 5,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              ),
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                physics: const NeverScrollableScrollPhysics(), // Disable swipe
                children: [
                  _WelcomeScreen(l10n: l10n),
                  _FeatureScreen(
                    l10n: l10n,
                    icon: Icons.medical_services_rounded,
                    iconColor: theme.colorScheme.primary,
                    title: l10n.onboardingHealthTitle,
                    description: l10n.onboardingHealthDescription,
                    features: [
                      l10n.onboardingHealthFeature1,
                      l10n.onboardingHealthFeature2,
                      l10n.onboardingHealthFeature3,
                    ],
                  ),
                  _FeatureScreen(
                    l10n: l10n,
                    icon: Icons.fitness_center_rounded,
                    iconColor: theme.colorScheme.secondary,
                    title: l10n.onboardingFitnessTitle,
                    description: l10n.onboardingFitnessDescription,
                    features: [
                      l10n.onboardingFitnessFeature1,
                      l10n.onboardingFitnessFeature2,
                      l10n.onboardingFitnessFeature3,
                    ],
                  ),
                  _GDPRConsentScreen(
                    l10n: l10n,
                    analyticsConsent: _analyticsConsent,
                    healthDataConsent: _healthDataConsent,
                    fitnessDataConsent: _fitnessDataConsent,
                    cloudBackupConsent: _cloudBackupConsent,
                    onAnalyticsChanged: (value) =>
                        setState(() => _analyticsConsent = value),
                    onHealthDataChanged: (value) =>
                        setState(() => _healthDataConsent = value),
                    onFitnessDataChanged: (value) =>
                        setState(() => _fitnessDataConsent = value),
                    onCloudBackupChanged: (value) =>
                        setState(() => _cloudBackupConsent = value),
                  ),
                  _PreferencesScreen(l10n: l10n),
                ],
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: _previousPage,
                      child: Text(l10n.back),
                    )
                  else
                    const SizedBox(width: 80),

                  // Page indicators
                  Row(
                    children: List.generate(
                      5,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index == _currentPage
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                  ),

                  // Next/Finish button
                  if (_currentPage < 4)
                    FilledButton(
                      onPressed: _nextPage,
                      child: Text(l10n.next),
                    )
                  else
                    FilledButton(
                      onPressed: _finishOnboarding,
                      child: Text(l10n.getStarted),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Welcome screen (Page 0)
class _WelcomeScreen extends StatelessWidget {
  const _WelcomeScreen({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_rounded,
            size: 100,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            l10n.onboardingWelcomeTitle,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.onboardingWelcomeSubtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.privacy_tip_rounded,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.onboardingPrivacyNote,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Feature introduction screen (Pages 1-2)
class _FeatureScreen extends StatelessWidget {
  const _FeatureScreen({
    required this.l10n,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.features,
  });

  final AppLocalizations l10n;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final List<String> features;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: iconColor,
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: iconColor,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      feature,
                      style: theme.textTheme.bodyLarge,
                    ),
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

/// GDPR Consent screen (Page 3)
class _GDPRConsentScreen extends StatelessWidget {
  const _GDPRConsentScreen({
    required this.l10n,
    required this.analyticsConsent,
    required this.healthDataConsent,
    required this.fitnessDataConsent,
    required this.cloudBackupConsent,
    required this.onAnalyticsChanged,
    required this.onHealthDataChanged,
    required this.onFitnessDataChanged,
    required this.onCloudBackupChanged,
  });

  final AppLocalizations l10n;
  final bool analyticsConsent;
  final bool healthDataConsent;
  final bool fitnessDataConsent;
  final bool cloudBackupConsent;
  final ValueChanged<bool> onAnalyticsChanged;
  final ValueChanged<bool> onHealthDataChanged;
  final ValueChanged<bool> onFitnessDataChanged;
  final ValueChanged<bool> onCloudBackupChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Icon(
              Icons.privacy_tip_rounded,
              size: 64,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.onboardingPrivacyTitle,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.onboardingPrivacyDescription,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Analytics consent
          _ConsentTile(
            title: l10n.gdprAnalyticsTitle,
            description: l10n.gdprAnalyticsDescription,
            value: analyticsConsent,
            onChanged: onAnalyticsChanged,
            isRequired: false,
          ),
          const SizedBox(height: 16),

          // Health data consent
          _ConsentTile(
            title: l10n.gdprHealthDataTitle,
            description: l10n.gdprHealthDataDescription,
            value: healthDataConsent,
            onChanged: onHealthDataChanged,
            isRequired: true,
          ),
          const SizedBox(height: 16),

          // Fitness data consent
          _ConsentTile(
            title: l10n.gdprFitnessDataTitle,
            description: l10n.gdprFitnessDataDescription,
            value: fitnessDataConsent,
            onChanged: onFitnessDataChanged,
            isRequired: true,
          ),
          const SizedBox(height: 16),

          // Cloud backup consent
          _ConsentTile(
            title: l10n.gdprCloudBackupTitle,
            description: l10n.gdprCloudBackupDescription,
            value: cloudBackupConsent,
            onChanged: onCloudBackupChanged,
            isRequired: false,
          ),

          const SizedBox(height: 24),
          Text(
            l10n.gdprNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

/// Consent checkbox tile
class _ConsentTile extends StatelessWidget {
  const _ConsentTile({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    required this.isRequired,
  });

  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isRequired)
                Chip(
                  label: Text(
                    'Required',
                    style: theme.textTheme.labelSmall,
                  ),
                  backgroundColor: theme.colorScheme.errorContainer,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              const SizedBox(width: 8),
              Switch(
                value: value,
                onChanged: isRequired ? null : onChanged,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// User preferences screen (Page 4)
class _PreferencesScreen extends ConsumerWidget {
  const _PreferencesScreen({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentLocale = ref.watch(localeSettingProvider);
    final currentTheme = ref.watch(themeSettingProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Icon(
              Icons.settings_rounded,
              size: 64,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.onboardingPreferencesTitle,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.onboardingPreferencesDescription,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Language selection
          Text(
            l10n.language,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<Locale>(
            segments: const [
              ButtonSegment(
                value: Locale('en'),
                label: Text('English'),
                icon: Icon(Icons.language),
              ),
              ButtonSegment(
                value: Locale('tr'),
                label: Text('Türkçe'),
                icon: Icon(Icons.language),
              ),
              ButtonSegment(
                value: Locale('de'),
                label: Text('Deutsch'),
                icon: Icon(Icons.language),
              ),
            ],
            selected: {currentLocale},
            onSelectionChanged: (newSelection) {
              ref.read(localeSettingProvider.notifier).setLocale(
                    newSelection.first,
                  );
            },
          ),
          const SizedBox(height: 32),

          // Theme selection
          Text(
            l10n.theme,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(l10n.themeSystem),
                icon: const Icon(Icons.brightness_auto),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(l10n.themeLight),
                icon: const Icon(Icons.light_mode),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text(l10n.themeDark),
                icon: const Icon(Icons.dark_mode),
              ),
            ],
            selected: {currentTheme},
            onSelectionChanged: (newSelection) {
              ref.read(themeSettingProvider.notifier).setThemeMode(
                    newSelection.first,
                  );
            },
          ),
          const SizedBox(height: 32),

          // Note
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.onboardingPreferencesNote,
                    style: theme.textTheme.bodySmall,
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
