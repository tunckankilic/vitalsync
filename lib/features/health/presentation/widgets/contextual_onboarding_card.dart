import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalsync/core/l10n/app_localizations.dart';
import 'package:vitalsync/core/theme/app_theme.dart';

/// SharedPreferences key prefix for dismissed onboarding cards.
const _dismissedKeyPrefix = 'onboarding_dismissed_';

class ContextualOnboardingCard extends ConsumerStatefulWidget {
  const ContextualOnboardingCard({
    super.key,
    this.cardType = 'medication_intro',
  });

  /// Unique identifier for this onboarding card type.
  /// Used to persist dismiss state per card.
  final String cardType;

  @override
  ConsumerState<ContextualOnboardingCard> createState() =>
      _ContextualOnboardingCardState();
}

class _ContextualOnboardingCardState
    extends ConsumerState<ContextualOnboardingCard>
    with SingleTickerProviderStateMixin {
  bool _isVisible = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkDismissed();
  }

  Future<void> _checkDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool(
      '$_dismissedKeyPrefix${widget.cardType}',
    );
    if (mounted) {
      setState(() {
        _isVisible = dismissed != true;
        _isLoading = false;
      });
    }
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_dismissedKeyPrefix${widget.cardType}', true);
    if (mounted) {
      setState(() => _isVisible = false);
    }
  }

  // To reset onboarding tips from Settings:
  // static Future<void> resetAll() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final keys = prefs.getKeys().where((k) => k.startsWith(_dismissedKeyPrefix));
  //   for (final key in keys) {
  //     await prefs.remove(key);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: !_isVisible
            ? const SizedBox.shrink()
            : Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.healthPrimary.withValues(alpha: 0.15)
                            : AppTheme.healthPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              AppTheme.healthPrimary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.healthPrimary.withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.waving_hand_rounded,
                                  color: AppTheme.healthPrimary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  AppLocalizations.of(context).welcomeToHealth,
                                  style:
                                      theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: 20,
                                ),
                                onPressed: _dismiss,
                                style: IconButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: theme
                                      .colorScheme.surface
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppLocalizations.of(context).onboardingHealthMessage,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () =>
                                  context.push('/health/add-medication'),
                              icon: const Icon(Icons.add_rounded),
                              label: Text(AppLocalizations.of(context).addFirstMedicationButton),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.healthPrimary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
