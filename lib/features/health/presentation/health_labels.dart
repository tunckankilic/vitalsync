/// VitalSync — Health Module: Localized Enum Labels.
///
/// Shared display names for the glucose and meal enums, so the list, form
/// and timeline screens all label a value the same way.
///
/// These are names, not judgements — a context or a source is stated, never
/// rated.
library;

import '../../../core/enums/glucose_source.dart';
import '../../../core/enums/meal_context.dart';
import '../../../core/l10n/app_localizations.dart';

extension MealContextLabel on MealContext {
  String label(AppLocalizations l10n) {
    switch (this) {
      case MealContext.fasting:
        return l10n.glucoseContextFasting;
      case MealContext.preMeal:
        return l10n.glucoseContextPreMeal;
      case MealContext.postMeal:
        return l10n.glucoseContextPostMeal;
      case MealContext.other:
        return l10n.glucoseContextOther;
    }
  }
}

extension GlucoseSourceLabel on GlucoseSource {
  String label(AppLocalizations l10n) {
    switch (this) {
      case GlucoseSource.healthKit:
        return l10n.glucoseSourceAppleHealth;
      case GlucoseSource.manual:
        return l10n.glucoseSourceManual;
    }
  }
}
