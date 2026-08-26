/// VitalSync — Fitness Module: Localized Enum Labels.
///
/// Display names for the exercise enums, so the library, detail screen and the
/// add-exercise dialog all label a value the same way and in the user's
/// language.
///
/// The enums keep their `displayName` getters: `InsightEngine` keys its
/// symptom/exercise correlation on the English category name and persists it,
/// so that string must not move with the interface language. Everything that
/// reaches a screen uses [ExerciseCategoryLabel.label] /
/// [EquipmentLabel.label] instead.
library;

import '../../../core/enums/equipment.dart';
import '../../../core/enums/exercise_category.dart';
import '../../../core/l10n/app_localizations.dart';

extension ExerciseCategoryLabel on ExerciseCategory {
  String label(AppLocalizations l10n) {
    switch (this) {
      case ExerciseCategory.chest:
        return l10n.exerciseCategoryChest;
      case ExerciseCategory.back:
        // Namespaced on purpose: the plain `back` key is the navigation
        // button, which is "Geri" in Turkish and "Zurück" in German.
        return l10n.exerciseCategoryBack;
      case ExerciseCategory.shoulders:
        return l10n.exerciseCategoryShoulders;
      case ExerciseCategory.arms:
        return l10n.exerciseCategoryArms;
      case ExerciseCategory.legs:
        return l10n.exerciseCategoryLegs;
      case ExerciseCategory.core:
        return l10n.exerciseCategoryCore;
      case ExerciseCategory.cardio:
        return l10n.exerciseCategoryCardio;
    }
  }
}

extension EquipmentLabel on Equipment {
  String label(AppLocalizations l10n) {
    switch (this) {
      case Equipment.barbell:
        return l10n.equipmentBarbell;
      case Equipment.dumbbell:
        return l10n.equipmentDumbbell;
      case Equipment.machine:
        return l10n.equipmentMachine;
      case Equipment.cable:
        return l10n.equipmentCable;
      case Equipment.bodyweight:
        return l10n.equipmentBodyweight;
      case Equipment.kettlebell:
        return l10n.equipmentKettlebell;
      case Equipment.other:
        return l10n.equipmentOther;
    }
  }
}
