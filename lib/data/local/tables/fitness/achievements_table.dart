/// VitalSync — Achievements Table (Fitness Module).
library;

import 'package:drift/drift.dart';

import '../../../../core/enums/achievement_type.dart';

/// Achievements table for gamification and motivation.
///
/// Contains both fitness and health-related achievements.
/// Achievements are unlocked when users meet specific requirements.
@DataClassName('AchievementData')
class Achievements extends Table {
  /// Primary key.
  IntColumn get id => integer().autoIncrement()();

  /// Type/category of this achievement.
  /// Stored as string, converted to/from AchievementType enum.
  TextColumn get type => textEnum<AchievementType>()();

  /// Achievement title (e.g., "Week Warrior", "Ton Club").
  TextColumn get title => text()();

  /// Description of what needs to be done to unlock this achievement.
  /// Example: "Complete workouts on 7 consecutive days"
  TextColumn get description => text()();

  /// Numeric requirement to unlock this achievement.
  /// Meaning depends on type:
  /// - streak: number of consecutive days
  /// - volume: total kg lifted
  /// - workouts: number of workouts completed
  /// - pr: number of PRs achieved
  /// - medication_compliance: % compliance threshold
  IntColumn get requirement => integer()();

  /// When this achievement was unlocked (nullable).
  /// Null means the achievement is still locked.
  DateTimeColumn get unlockedAt => dateTime().nullable()();

  /// Icon name/identifier for UI display.
  /// Can reference asset names or icon library identifiers.
  TextColumn get iconName => text()();
}
