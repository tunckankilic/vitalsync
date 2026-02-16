/// VitalSync — Achievements Screen.
///
/// Displays user achievements - unlocked and locked.
/// Shows progress toward locked achievements with category filtering.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vitalsync/core/enums/achievement_type.dart';
import 'package:vitalsync/core/l10n/app_localizations.dart';
import 'package:vitalsync/core/theme/app_theme.dart';
import 'package:vitalsync/domain/entities/fitness/achievement.dart';
import 'package:vitalsync/features/fitness/presentation/providers/achievement_provider.dart';
import 'package:vitalsync/presentation/widgets/glassmorphic_app_bar.dart';
import 'package:vitalsync/presentation/widgets/glassmorphic_card.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() =>
      _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  AchievementType? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final achievementsAsync = ref.watch(achievementsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassmorphicAppBar(title: l10n.achievements),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              AppTheme.fitnessPrimary.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: achievementsAsync.when(
            data: (allAchievements) {
              final unlocked =
                  allAchievements
                      .where((a) => a.unlockedAt != null)
                      .toList();
              final locked =
                  allAchievements
                      .where((a) => a.unlockedAt == null)
                      .toList();

              // Apply category filter
              final filteredUnlocked = _selectedCategory == null
                  ? unlocked
                  : unlocked
                        .where((a) => a.type == _selectedCategory)
                        .toList();
              final filteredLocked = _selectedCategory == null
                  ? locked
                  : locked
                        .where((a) => a.type == _selectedCategory)
                        .toList();

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Header stats
                  _HeaderStatsCard(
                    unlocked: unlocked.length,
                    total: allAchievements.length,
                  ),

                  const SizedBox(height: 16),

                  // Category filter chips
                  _CategoryFilter(
                    selectedCategory: _selectedCategory,
                    onCategoryChanged: (category) {
                      setState(() => _selectedCategory = category);
                    },
                  ),

                  const SizedBox(height: 16),

                  // Unlocked section
                  if (filteredUnlocked.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        l10n.unlocked,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: filteredUnlocked.length,
                      itemBuilder: (context, index) {
                        return _UnlockedAchievementCard(
                          achievement: filteredUnlocked[index],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Locked section
                  if (filteredLocked.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        l10n.locked,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: filteredLocked.length,
                      itemBuilder: (context, index) {
                        return _LockedAchievementCard(
                          achievement: filteredLocked[index],
                        );
                      },
                    ),
                  ],

                  // Empty state
                  if (filteredUnlocked.isEmpty && filteredLocked.isEmpty)
                    _EmptyState(),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text(AppLocalizations.of(context).errorGeneric(error))),
          ),
        ),
      ),
    );
  }
}

class _HeaderStatsCard extends StatelessWidget {
  const _HeaderStatsCard({required this.unlocked, required this.total});

  final int unlocked;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final progress = total > 0 ? unlocked / total : 0.0;

    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              l10n.achievementProgress(unlocked, total),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.fitnessPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.achievements,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.fitnessPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  final AchievementType? selectedCategory;
  final ValueChanged<AchievementType?> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChip(l10n.all, selectedCategory == null, () {
            onCategoryChanged(null);
          }, theme),
          const SizedBox(width: 8),
          _buildChip(
            l10n.streak,
            selectedCategory == AchievementType.streak,
            () => onCategoryChanged(AchievementType.streak),
            theme,
          ),
          const SizedBox(width: 8),
          _buildChip(
            l10n.totalVolume,
            selectedCategory == AchievementType.volume,
            () => onCategoryChanged(AchievementType.volume),
            theme,
          ),
          const SizedBox(width: 8),
          _buildChip(
            l10n.workouts,
            selectedCategory == AchievementType.workouts,
            () => onCategoryChanged(AchievementType.workouts),
            theme,
          ),
          const SizedBox(width: 8),
          _buildChip(
            l10n.personalRecords,
            selectedCategory == AchievementType.pr,
            () => onCategoryChanged(AchievementType.pr),
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildChip(
    String label,
    bool isSelected,
    VoidCallback onTap,
    ThemeData theme,
  ) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      selectedColor: AppTheme.fitnessPrimary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class _UnlockedAchievementCard extends StatelessWidget {
  const _UnlockedAchievementCard({required this.achievement});

  final Achievement achievement;

  IconData _getIconForName(String iconName) {
    switch (iconName) {
      case 'fitness_center':
        return Icons.fitness_center;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'trending_up':
        return Icons.trending_up;
      case 'star':
        return Icons.star;
      case 'medication':
        return Icons.medication;
      default:
        return Icons.emoji_events;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassmorphicCard(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.fitnessPrimary.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getIconForName(achievement.iconName),
                size: 40,
                color: AppTheme.fitnessPrimary,
              ),
              const SizedBox(height: 8),
              Text(
                achievement.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                achievement.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (achievement.unlockedAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  _formatRelativeDate(achievement.unlockedAt!, AppLocalizations.of(context)),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.fitnessPrimary,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatRelativeDate(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return l10n.today;
    if (diff.inDays == 1) return l10n.yesterday;
    if (diff.inDays < 7) return l10n.daysAgo(diff.inDays);
    if (diff.inDays < 30) return l10n.weeksAgo((diff.inDays / 7).floor());
    return l10n.monthsAgo((diff.inDays / 30).floor());
  }
}

class _LockedAchievementCard extends StatelessWidget {
  const _LockedAchievementCard({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Opacity(
      opacity: 0.5,
      child: GlassmorphicCard(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 40,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  Icon(
                    Icons.lock,
                    size: 18,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                achievement.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '???',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noAchievementsYet,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.keepWorkingToUnlock,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
