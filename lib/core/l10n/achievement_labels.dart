/// VitalSync — Localized Achievement Copy.
///
/// Achievements are seeded into the database as English rows and keyed by a
/// stable [Achievement.iconName]. Translating them at display time — rather
/// than storing translated text — means a language change takes effect
/// immediately and needs no re-seed and no migration, and it keeps the
/// unlock rules reading one canonical row per achievement.
///
/// This lives in `core/l10n` rather than beside the achievements screen
/// because two layers need it: the screen, and [NotificationService] when it
/// announces an unlock without a widget context.
///
/// Unknown keys fall back to the stored English text, so an achievement
/// added to the seed but not yet translated still renders something real
/// instead of a blank card.
library;

import '../../domain/entities/fitness/achievement.dart';
import 'app_localizations.dart';

extension AchievementLabel on Achievement {
  /// The achievement's name, e.g. "Week Warrior".
  String localizedTitle(AppLocalizations l10n) {
    switch (iconName) {
      case 'fitness_first_step':
        return l10n.achievementFitnessFirstStepTitle;
      case 'fitness_week_warrior':
        return l10n.achievementFitnessWeekWarriorTitle;
      case 'fitness_monthly_master':
        return l10n.achievementFitnessMonthlyMasterTitle;
      case 'fitness_iron_will':
        return l10n.achievementFitnessIronWillTitle;
      case 'fitness_ton_club':
        return l10n.achievementFitnessTonClubTitle;
      case 'fitness_heavy_lifter':
        return l10n.achievementFitnessHeavyLifterTitle;
      case 'fitness_powerhouse':
        return l10n.achievementFitnessPowerhouseTitle;
      case 'fitness_mountain_mover':
        return l10n.achievementFitnessMountainMoverTitle;
      case 'fitness_beginner':
        return l10n.achievementFitnessBeginnerTitle;
      case 'fitness_consistent':
        return l10n.achievementFitnessConsistentTitle;
      case 'fitness_dedicated':
        return l10n.achievementFitnessDedicatedTitle;
      case 'fitness_gym_rat':
        return l10n.achievementFitnessGymRatTitle;
      case 'fitness_legend':
        return l10n.achievementFitnessLegendTitle;
      case 'fitness_first_pr':
        return l10n.achievementFitnessFirstPrTitle;
      case 'fitness_record_breaker':
        return l10n.achievementFitnessRecordBreakerTitle;
      case 'fitness_elite':
        return l10n.achievementFitnessEliteTitle;
      case 'health_perfect_day':
        return l10n.achievementHealthPerfectDayTitle;
      case 'health_week_wellness':
        return l10n.achievementHealthWeekWellnessTitle;
      case 'health_hero':
        return l10n.achievementHealthHeroTitle;
      case 'cross_balance_master':
        return l10n.achievementCrossBalanceMasterTitle;
      case 'cross_synced_up':
        return l10n.achievementCrossSyncedUpTitle;
      case 'cross_wellness_warrior':
        return l10n.achievementCrossWellnessWarriorTitle;
      default:
        return title;
    }
  }

  /// What the user has to do to unlock it.
  ///
  /// These state a requirement, never a judgement about the user.
  String localizedDescription(AppLocalizations l10n) {
    switch (iconName) {
      case 'fitness_first_step':
        return l10n.achievementFitnessFirstStepDesc;
      case 'fitness_week_warrior':
        return l10n.achievementFitnessWeekWarriorDesc;
      case 'fitness_monthly_master':
        return l10n.achievementFitnessMonthlyMasterDesc;
      case 'fitness_iron_will':
        return l10n.achievementFitnessIronWillDesc;
      case 'fitness_ton_club':
        return l10n.achievementFitnessTonClubDesc;
      case 'fitness_heavy_lifter':
        return l10n.achievementFitnessHeavyLifterDesc;
      case 'fitness_powerhouse':
        return l10n.achievementFitnessPowerhouseDesc;
      case 'fitness_mountain_mover':
        return l10n.achievementFitnessMountainMoverDesc;
      case 'fitness_beginner':
        return l10n.achievementFitnessBeginnerDesc;
      case 'fitness_consistent':
        return l10n.achievementFitnessConsistentDesc;
      case 'fitness_dedicated':
        return l10n.achievementFitnessDedicatedDesc;
      case 'fitness_gym_rat':
        return l10n.achievementFitnessGymRatDesc;
      case 'fitness_legend':
        return l10n.achievementFitnessLegendDesc;
      case 'fitness_first_pr':
        return l10n.achievementFitnessFirstPrDesc;
      case 'fitness_record_breaker':
        return l10n.achievementFitnessRecordBreakerDesc;
      case 'fitness_elite':
        return l10n.achievementFitnessEliteDesc;
      case 'health_perfect_day':
        return l10n.achievementHealthPerfectDayDesc;
      case 'health_week_wellness':
        return l10n.achievementHealthWeekWellnessDesc;
      case 'health_hero':
        return l10n.achievementHealthHeroDesc;
      case 'cross_balance_master':
        return l10n.achievementCrossBalanceMasterDesc;
      case 'cross_synced_up':
        return l10n.achievementCrossSyncedUpDesc;
      case 'cross_wellness_warrior':
        return l10n.achievementCrossWellnessWarriorDesc;
      default:
        return description;
    }
  }
}

/// Every [Achievement.iconName] this file translates.
///
/// Exposed so a test can prove the seed and the switches above stay in step:
/// a seeded achievement missing here would silently fall back to English.
const kLocalizedAchievementIconNames = <String>{
  'fitness_first_step',
  'fitness_week_warrior',
  'fitness_monthly_master',
  'fitness_iron_will',
  'fitness_ton_club',
  'fitness_heavy_lifter',
  'fitness_powerhouse',
  'fitness_mountain_mover',
  'fitness_beginner',
  'fitness_consistent',
  'fitness_dedicated',
  'fitness_gym_rat',
  'fitness_legend',
  'fitness_first_pr',
  'fitness_record_breaker',
  'fitness_elite',
  'health_perfect_day',
  'health_week_wellness',
  'health_hero',
  'cross_balance_master',
  'cross_synced_up',
  'cross_wellness_warrior',
};
