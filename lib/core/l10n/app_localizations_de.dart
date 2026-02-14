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
  String get exerciseName => 'Übungsname';

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
  String get workoutHome => 'Trainings';

  @override
  String get recentWorkouts => 'Letzte Trainings';

  @override
  String get workoutTemplates => 'Vorlagen';

  @override
  String get createNewTemplate => 'Neue Vorlage erstellen';

  @override
  String get quickStats => 'Schnellstatistik';

  @override
  String get thisWeeksVolume => 'Volumen dieser Woche';

  @override
  String get thisWeeksWorkouts => 'Trainings dieser Woche';

  @override
  String get vsLastWeek => 'vs. letzte Woche';

  @override
  String get activeWorkout => 'Aktives Training';

  @override
  String get finishWorkout => 'Beenden';

  @override
  String get discardWorkout => 'Training verwerfen';

  @override
  String get discardWorkoutMessage =>
      'Bist du sicher? Dein Training wird nicht gespeichert.';

  @override
  String get previousSession => 'Vorherige';

  @override
  String setNumber(int number) {
    return 'Satz $number';
  }

  @override
  String get weight => 'Gewicht';

  @override
  String get reps => 'Wiederholungen';

  @override
  String get warmup => 'Aufwärmen';

  @override
  String get completeSet => 'Abschließen';

  @override
  String get restTimer => 'Pausentimer';

  @override
  String get skipRest => 'Pause überspringen';

  @override
  String get readyForNextSet => 'Bereit für den nächsten Satz?';

  @override
  String get addExercise => 'Übung hinzufügen';

  @override
  String get seconds => 'Sekunden';

  @override
  String get workoutSummary => 'Trainingszusammenfassung';

  @override
  String get duration => 'Dauer';

  @override
  String get totalVolume => 'Gesamtvolumen';

  @override
  String get totalSets => 'Gesamtsätze';

  @override
  String get exerciseCount => 'Übungen';

  @override
  String get newPRs => 'Neue PRs';

  @override
  String get rateWorkout => 'Training bewerten';

  @override
  String get workoutNotes => 'Trainingsnotizen';

  @override
  String get shareWorkout => 'Training teilen';

  @override
  String get storyFormat => 'Story-Format';

  @override
  String get compactCard => 'Kompakte Karte';

  @override
  String get exportJSON => 'JSON exportieren';

  @override
  String get trackedWithVitalSync => 'Verfolgt mit VitalSync';

  @override
  String get exerciseLibrary => 'Übungsbibliothek';

  @override
  String get searchExercises => 'Übungen suchen...';

  @override
  String get allCategories => 'Alle';

  @override
  String get chest => 'Brust';

  @override
  String get back => 'Rücken';

  @override
  String get shoulders => 'Schultern';

  @override
  String get arms => 'Arme';

  @override
  String get legs => 'Beine';

  @override
  String get core => 'Core';

  @override
  String get cardio => 'Kardio';

  @override
  String get exerciseDetails => 'Übungsdetails';

  @override
  String get instructions => 'Anweisungen';

  @override
  String get exerciseHistory => 'Verlauf';

  @override
  String get personalRecord => 'Persönlicher Rekord';

  @override
  String get weightProgression => 'Gewichtsprogression';

  @override
  String get createCustomExercise => 'Benutzerdefinierte Übung erstellen';

  @override
  String get progress => 'Fortschritt';

  @override
  String get oneWeek => '1W';

  @override
  String get oneMonth => '1M';

  @override
  String get threeMonths => '3M';

  @override
  String get sixMonths => '6M';

  @override
  String get oneYear => '1J';

  @override
  String get volumeProgression => 'Volumenprogression';

  @override
  String get workoutFrequency => 'Trainingshäufigkeit';

  @override
  String get personalRecords => 'Persönliche Rekorde';

  @override
  String get oneRepMax => '1RM';

  @override
  String get selectExercise => 'Übung auswählen';

  @override
  String get calendar => 'Kalender';

  @override
  String get monthlyStats => 'Monatsstatistik';

  @override
  String get totalWorkouts => 'Gesamttrainings';

  @override
  String get streak => 'Serie';

  @override
  String get vsPreviousMonth => 'vs. vorheriger Monat';

  @override
  String get workoutDetails => 'Trainingsdetails';

  @override
  String get achievements => 'Erfolge';

  @override
  String get unlocked => 'Freigeschaltet';

  @override
  String get locked => 'Gesperrt';

  @override
  String get nearCompletion => 'Fast geschafft!';

  @override
  String achievementProgress(int current, int total) {
    return '$current / $total';
  }

  @override
  String get fitnessCategory => 'Fitness';

  @override
  String get healthCategory => 'Gesundheit';

  @override
  String get crossModuleCategory => 'Modulübergreifend';

  @override
  String get templateName => 'Vorlagenname';

  @override
  String get estimatedDuration => 'Geschätzte Dauer';

  @override
  String get exercises => 'Übungen';

  @override
  String get editTemplate => 'Vorlage bearbeiten';

  @override
  String get deleteTemplate => 'Vorlage löschen';

  @override
  String get deleteTemplateConfirmation =>
      'Bist du sicher, dass du diese Vorlage löschen möchtest?';

  @override
  String get sets => 'Sätze';

  @override
  String get restTime => 'Pausenzeit';

  @override
  String get addExerciseToTemplate => 'Übung hinzufügen';

  @override
  String get noWorkoutsYet => 'Noch keine Trainings';

  @override
  String get startYourFirstWorkout =>
      'Starte dein erstes Training, um deinen Fortschritt zu verfolgen';

  @override
  String get noTemplatesYet => 'Noch keine Vorlagen';

  @override
  String get createYourFirstTemplate =>
      'Erstelle eine Vorlage, um schnell Trainings zu starten';

  @override
  String get noExercisesFound => 'Keine Übungen gefunden';

  @override
  String get noAchievementsYet => 'Noch keine Erfolge';

  @override
  String get keepWorkingToUnlock =>
      'Trainiere weiter, um Erfolge freizuschalten';

  @override
  String get firstWorkoutComplete => 'Erstes Training abgeschlossen! 🔥';

  @override
  String get consistencyIsKey =>
      'Beständigkeit ist der Schlüssel! Halte deine Serie aufrecht';

  @override
  String get newPRCelebration => 'Neuer persönlicher Rekord! 🏆';

  @override
  String get shareYourPR => 'Teile deine Leistung';

  @override
  String streakMilestone(int days) {
    return '$days Tage Serie! 🔥';
  }

  @override
  String get shareYourStreak => 'Deine Serie teilen?';

  @override
  String get kg => 'kg';

  @override
  String get lbs => 'lbs';

  @override
  String get min => 'min';

  @override
  String get noExercises => 'No exercises in this workout';

  @override
  String get muscleGroup => 'Muskelgruppe';

  @override
  String get equipment => 'Ausrüstung';

  @override
  String get exerciseAdded => 'Übung erfolgreich hinzugefügt';
}
