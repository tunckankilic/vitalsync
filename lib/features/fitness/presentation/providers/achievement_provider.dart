/// VitalSync — Fitness Module: Achievement Providers.
///
/// Riverpod 2.0 providers for achievement tracking and unlocking
/// with code generation.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../domain/entities/fitness/achievement.dart';
import '../../../../domain/repositories/fitness/achievement_repository.dart';

part 'achievement_provider.g.dart';

/// Provider for the AchievementRepository instance
@Riverpod(keepAlive: true)
AchievementRepository achievementRepository(Ref ref) {
  return getIt<AchievementRepository>();
}

/// Provider for the AnalyticsService instance
@Riverpod(keepAlive: true)
AnalyticsService achievementAnalyticsService(Ref ref) {
  return getIt<AnalyticsService>();
}

/// Stream provider for all achievements
@riverpod
Stream<List<Achievement>> achievements(Ref ref) {
  final repository = ref.watch(achievementRepositoryProvider);
  return repository.watchAll();
}

/// Provider for unlocked achievements
@riverpod
Future<List<Achievement>> unlockedAchievements(Ref ref) async {
  final repository = ref.watch(achievementRepositoryProvider);
  return repository.getUnlocked();
}

/// Provider for locked achievements
@riverpod
Future<List<Achievement>> lockedAchievements(Ref ref) async {
  final repository = ref.watch(achievementRepositoryProvider);
  return repository.getLocked();
}

/// State provider for newly unlocked achievement
/// Used to trigger unlock animation in UI
@riverpod
class NewlyUnlocked extends _$NewlyUnlocked {
  @override
  Achievement? build() => null;

  /// Set the newly unlocked achievement
  void set(Achievement? achievement) {
    state = achievement;
  }

  /// Clear the newly unlocked achievement
  void clear() {
    state = null;
  }
}

/// Notifier for achievement operations
@riverpod
class AchievementNotifier extends _$AchievementNotifier {
  @override
  FutureOr<void> build() {
    // No initial state needed
  }

  /// Check for and unlock new achievements
  /// This should be called after significant actions
  /// (e.g., completing a workout, logging medication)
  Future<void> checkForNewAchievements() async {
    state = const AsyncValue.loading();

    final repository = ref.read(achievementRepositoryProvider);
    final analytics = ref.read(achievementAnalyticsServiceProvider);
    final newlyUnlockedNotifier = ref.read(newlyUnlockedProvider.notifier);

    state = await AsyncValue.guard(() async {
      // Get achievements before check
      final beforeUnlocked = await repository.getUnlocked();
      final beforeUnlockedIds = beforeUnlocked.map((a) => a.id).toSet();

      // Check and unlock achievements
      await repository.checkAndUnlock();

      // Get achievements after check
      final afterUnlocked = await repository.getUnlocked();

      // Find newly unlocked achievements
      final newlyUnlocked = afterUnlocked
          .where((a) => !beforeUnlockedIds.contains(a.id))
          .toList();

      // Handle newly unlocked achievements
      for (final achievement in newlyUnlocked) {
        // Set for UI animation
        newlyUnlockedNotifier.set(achievement);

        // Fire analytics event
        await analytics.logAchievementUnlocked(
          achievementType: achievement.type.toString(),
          achievementId: achievement.id.toString(),
        );
      }
    });

    if (state.hasError) {
      throw state.error!;
    }
  }
}
