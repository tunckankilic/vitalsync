// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'VitalSync';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get health => 'Gesundheit';

  @override
  String get fitness => 'Fitness';

  @override
  String get settings => 'Einstellungen';

  @override
  String get profile => 'Profil';

  @override
  String get syncOnline => 'Online';

  @override
  String get syncOffline => 'Offline';

  @override
  String get syncing => 'Synchronisierung';

  @override
  String get syncOnlineTooltip => 'Online - Daten synchronisiert';

  @override
  String get syncOfflineTooltip =>
      'Offline - Änderungen werden synchronisiert, wenn online';

  @override
  String get syncingTooltip => 'Synchronisierung läuft...';

  @override
  String get syncSemanticsOnline => 'Online';

  @override
  String get syncSemanticsOffline => 'Offline';

  @override
  String get syncSemanticsSyncing => 'Daten werden synchronisiert';

  @override
  String get insights => 'Einblicke';

  @override
  String insightsCountSemantics(int count) {
    return 'Einblicke, $count ungelesen';
  }

  @override
  String insightsCountTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'neue Einblicke',
      one: 'neuer Einblick',
    );
    return '$count $_temp0';
  }

  @override
  String get addMedication => 'Medikament hinzufügen';

  @override
  String get logSymptom => 'Symptom erfassen';

  @override
  String get startWorkout => 'Training starten';

  @override
  String get quickAddMenuOpen => 'Schnellzugriffsmenü öffnen';

  @override
  String get quickAddMenuClose => 'Schnellzugriffsmenü schließen';

  @override
  String get dashboardTabSemantics => 'Dashboard-Tab';

  @override
  String get dashboardTabSelectedSemantics => 'Dashboard-Tab, ausgewählt';

  @override
  String get dashboardTabTooltip =>
      'Zeigen Sie Ihr vereinheitlichtes Gesundheits- und Fitness-Dashboard an';

  @override
  String get healthTabSemantics => 'Gesundheits-Tab';

  @override
  String get healthTabSelectedSemantics => 'Gesundheits-Tab, ausgewählt';

  @override
  String get healthTabTooltip => 'Medikamente und Symptome verwalten';

  @override
  String get fitnessTabSemantics => 'Fitness-Tab';

  @override
  String get fitnessTabSelectedSemantics => 'Fitness-Tab, ausgewählt';

  @override
  String get fitnessTabTooltip => 'Trainings und Fortschritt verfolgen';

  @override
  String get settingsSemantics => 'Einstellungen';

  @override
  String get settingsTooltip => 'Einstellungen öffnen';

  @override
  String get profileSemantics => 'Profil';

  @override
  String get returnToWorkout => 'Zurück zum Training';

  @override
  String get timeElapsed => 'Verstrichene Zeit';

  @override
  String get goodMorning => 'Guten Morgen';

  @override
  String get goodAfternoon => 'Guten Tag';

  @override
  String get goodEvening => 'Guten Abend';

  @override
  String get goodNight => 'Gute Nacht';

  @override
  String get todaysMedications => 'Heutige Medikamente';

  @override
  String nextMedicationIn(Object time) {
    return 'Nächste in $time';
  }

  @override
  String get noUpcomingMedications => 'Keine anstehenden Medikamente';

  @override
  String get hoursShort => 'Std';

  @override
  String get minutesShort => 'Min';

  @override
  String get currentStreak => 'Tage Serie';

  @override
  String get inProgress => 'In Bearbeitung';

  @override
  String get weeklyOverview => 'Wöchentliche Übersicht';

  @override
  String get thisWeek => 'Diese Woche';

  @override
  String get last30Days => 'Letzte 30 Tage';

  @override
  String get medicationCompliance => 'Medikation';

  @override
  String get workoutVolume => 'Training';

  @override
  String get viewReport => 'Bericht anzeigen';

  @override
  String get recentActivity => 'Letzte Aktivitäten';

  @override
  String get viewAll => 'Alle anzeigen';

  @override
  String get noRecentActivity => 'Keine letzten Aktivitäten';

  @override
  String get dataCollecting =>
      'Einblicke werden hier angezeigt, sobald Daten gesammelt werden';

  @override
  String get startFirstWorkout => 'Starten Sie Ihr erstes Training';

  @override
  String get addFirstMedication => 'Fügen Sie Ihr erstes Medikament hinzu';

  @override
  String get dismissInsightTitle => 'Einblick verwerfen';

  @override
  String get dismissInsightMessage =>
      'Möchten Sie diesen Einblick wirklich verwerfen?';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get dismiss => 'Verwerfen';

  @override
  String get errorLoadingDashboard => 'Fehler beim Laden des Dashboards';

  @override
  String get retry => 'Wiederholen';

  @override
  String get active => 'Aktiv';

  @override
  String get all => 'Alle';

  @override
  String get completed => 'Abgeschlossen';

  @override
  String get searchMedication => 'Medikament suchen...';

  @override
  String get noMedicationsFound => 'Keine Medikamente gefunden';

  @override
  String get editMedication => 'Medikament bearbeiten';

  @override
  String get medicationName => 'Medikamentenname';

  @override
  String get dosage => 'Dosierung';

  @override
  String get requiredField => 'Dieses Feld ist erforderlich';

  @override
  String get frequency => 'Häufigkeit';

  @override
  String get scheduledTimes => 'Geplante Zeiten';

  @override
  String get color => 'Farbe';

  @override
  String get saving => 'Speichern...';

  @override
  String get save => 'Speichern';

  @override
  String get medicationDetails => 'Medikamentendetails';

  @override
  String get deleteMedication => 'Medikament löschen';

  @override
  String get deleteConfirmation =>
      'Sind Sie sicher, dass Sie dieses Medikament löschen möchten?';

  @override
  String get delete => 'Löschen';

  @override
  String get complianceHistory => 'Einhaltungshistorie';

  @override
  String get history => 'Verlauf';

  @override
  String get noLogsYet => 'Noch keine Einträge';

  @override
  String get takenAt => 'Eingenommen um';

  @override
  String get shareReport => 'Bericht teilen';

  @override
  String get symptoms => 'Symptome';

  @override
  String get mostFrequent => 'Häufigste';

  @override
  String get recentTimeline => 'Jüngster Verlauf';

  @override
  String get noSymptomsLogged => 'Keine Symptome protokolliert';

  @override
  String get symptomName => 'Symptomname';

  @override
  String get severity => 'Schweregrad';

  @override
  String get date => 'Datum';

  @override
  String get time => 'Zeit';

  @override
  String get notes => 'Notizen';

  @override
  String get healthTimeline => 'Gesundheits-Zeitlinie';

  @override
  String get compliance => 'Einhaltung';

  @override
  String get medications => 'Medikamente';

  @override
  String get complianceTrend => 'Einhaltungstrend';

  @override
  String get skip => 'Überspringen';

  @override
  String get take => 'Einnehmen';

  @override
  String get workoutHome => 'Workouts';

  @override
  String get recentWorkouts => 'Recent Workouts';

  @override
  String get workoutTemplates => 'Templates';

  @override
  String get createNewTemplate => 'Create New Template';

  @override
  String get quickStats => 'Quick Stats';

  @override
  String get thisWeeksVolume => 'This Week\'s Volume';

  @override
  String get thisWeeksWorkouts => 'This Week\'s Workouts';

  @override
  String get vsLastWeek => 'vs last week';

  @override
  String get activeWorkout => 'Active Workout';

  @override
  String get finishWorkout => 'Finish';

  @override
  String get discardWorkout => 'Discard Workout';

  @override
  String get discardWorkoutMessage =>
      'Are you sure? Your workout won\'t be saved.';

  @override
  String get previousSession => 'Previous';

  @override
  String setNumber(int number) {
    return 'Set $number';
  }

  @override
  String get weight => 'Weight';

  @override
  String get reps => 'Reps';

  @override
  String get warmup => 'Warmup';

  @override
  String get completeSet => 'Complete';

  @override
  String get restTimer => 'Rest Timer';

  @override
  String get skipRest => 'Skip Rest';

  @override
  String get readyForNextSet => 'Ready for next set?';

  @override
  String get addExercise => 'Add Exercise';

  @override
  String get seconds => 'seconds';

  @override
  String get workoutSummary => 'Workout Summary';

  @override
  String get duration => 'Duration';

  @override
  String get totalVolume => 'Total Volume';

  @override
  String get totalSets => 'Total Sets';

  @override
  String get exerciseCount => 'Exercises';

  @override
  String get newPRs => 'New PRs';

  @override
  String get rateWorkout => 'Rate Your Workout';

  @override
  String get workoutNotes => 'Workout Notes';

  @override
  String get shareWorkout => 'Share Workout';

  @override
  String get storyFormat => 'Story Format';

  @override
  String get compactCard => 'Compact Card';

  @override
  String get exportJSON => 'Export JSON';

  @override
  String get trackedWithVitalSync => 'Tracked with VitalSync';

  @override
  String get exerciseLibrary => 'Exercise Library';

  @override
  String get searchExercises => 'Search exercises...';

  @override
  String get allCategories => 'All';

  @override
  String get chest => 'Chest';

  @override
  String get back => 'Back';

  @override
  String get shoulders => 'Shoulders';

  @override
  String get arms => 'Arms';

  @override
  String get legs => 'Legs';

  @override
  String get core => 'Core';

  @override
  String get cardio => 'Cardio';

  @override
  String get exerciseDetails => 'Exercise Details';

  @override
  String get instructions => 'Instructions';

  @override
  String get exerciseHistory => 'History';

  @override
  String get personalRecord => 'Personal Record';

  @override
  String get weightProgression => 'Weight Progression';

  @override
  String get createCustomExercise => 'Create Custom Exercise';

  @override
  String get progress => 'Progress';

  @override
  String get oneWeek => '1W';

  @override
  String get oneMonth => '1M';

  @override
  String get threeMonths => '3M';

  @override
  String get sixMonths => '6M';

  @override
  String get oneYear => '1Y';

  @override
  String get volumeProgression => 'Volume Progression';

  @override
  String get workoutFrequency => 'Workout Frequency';

  @override
  String get personalRecords => 'Personal Records';

  @override
  String get oneRepMax => '1RM';

  @override
  String get selectExercise => 'Select Exercise';

  @override
  String get calendar => 'Calendar';

  @override
  String get monthlyStats => 'Monthly Stats';

  @override
  String get totalWorkouts => 'Total Workouts';

  @override
  String get streak => 'Streak';

  @override
  String get vsPreviousMonth => 'vs previous month';

  @override
  String get workoutDetails => 'Workout Details';

  @override
  String get achievements => 'Achievements';

  @override
  String get unlocked => 'Unlocked';

  @override
  String get locked => 'Locked';

  @override
  String get nearCompletion => 'Almost there!';

  @override
  String achievementProgress(int current, int total) {
    return '$current / $total';
  }

  @override
  String get fitnessCategory => 'Fitness';

  @override
  String get healthCategory => 'Health';

  @override
  String get crossModuleCategory => 'Cross-Module';

  @override
  String get templateName => 'Template Name';

  @override
  String get estimatedDuration => 'Estimated Duration';

  @override
  String get exercises => 'Exercises';

  @override
  String get editTemplate => 'Edit Template';

  @override
  String get deleteTemplate => 'Delete Template';

  @override
  String get deleteTemplateConfirmation =>
      'Are you sure you want to delete this template?';

  @override
  String get sets => 'Sets';

  @override
  String get restTime => 'Rest Time';

  @override
  String get addExerciseToTemplate => 'Add Exercise';

  @override
  String get noWorkoutsYet => 'No workouts yet';

  @override
  String get startYourFirstWorkout =>
      'Start your first workout to begin tracking your progress';

  @override
  String get noTemplatesYet => 'No templates yet';

  @override
  String get createYourFirstTemplate =>
      'Create a template to quickly start workouts';

  @override
  String get noExercisesFound => 'No exercises found';

  @override
  String get noAchievementsYet => 'No achievements yet';

  @override
  String get keepWorkingToUnlock => 'Keep working out to unlock achievements';

  @override
  String get firstWorkoutComplete => 'First workout complete! 🔥';

  @override
  String get consistencyIsKey => 'Consistency is key! Keep your streak going';

  @override
  String get newPRCelebration => 'New Personal Record! 🏆';

  @override
  String get shareYourPR => 'Share your achievement';

  @override
  String streakMilestone(int days) {
    return '$days Day Streak! 🔥';
  }

  @override
  String get shareYourStreak => 'Share your streak?';

  @override
  String get kg => 'kg';

  @override
  String get lbs => 'lbs';

  @override
  String get min => 'min';
}
