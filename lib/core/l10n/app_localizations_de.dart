// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'VitalSynch';

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
  String get syncSemanticsError => 'Synchronisierungsfehler';

  @override
  String get syncErrorTooltip =>
      'Synchronisierungsfehler - zum Wiederholen tippen';

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
  String get trackedWithVitalSynch => 'Verfolgt mit VitalSynch';

  @override
  String get exerciseLibrary => 'Übungsbibliothek';

  @override
  String get searchExercises => 'Übungen suchen...';

  @override
  String get allCategories => 'Alle';

  @override
  String get chest => 'Brust';

  @override
  String get back => 'Zurück';

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
  String get totalWorkouts => 'Gesamte Trainings';

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

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get userNotFound => 'User not found';

  @override
  String get personalInformation => 'Personal Information';

  @override
  String get fullName => 'Full Name';

  @override
  String get enterFullName => 'Please enter your name';

  @override
  String get dateOfBirth => 'Date of Birth';

  @override
  String get selectDate => 'Select Date';

  @override
  String get gender => 'Gender';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderOther => 'Other';

  @override
  String get genderPreferNotToSay => 'Prefer not to say';

  @override
  String get emergencyContact => 'Emergency Contact';

  @override
  String get contactName => 'Contact Name';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get profileUpdatedSuccess => 'Profile updated successfully';

  @override
  String profileUpdateError(Object error) {
    return 'Error updating profile: $error';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Thema';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get materialYou => 'Material You';

  @override
  String get materialYouSubtitle => 'Use dynamic colors from wallpaper';

  @override
  String get language => 'Sprache';

  @override
  String get languageEn => 'English';

  @override
  String get languageTr => 'Türkçe';

  @override
  String get languageDe => 'Deutsch';

  @override
  String get notifications => 'Notifications';

  @override
  String get enableNotifications => 'Enable Notifications';

  @override
  String get units => 'Units';

  @override
  String get unitSystem => 'Unit System';

  @override
  String get unitMetric => 'Metric (kg, cm)';

  @override
  String get unitImperial => 'Imperial (lbs, in)';

  @override
  String get privacyData => 'Privacy & Data';

  @override
  String get manageConsents => 'Manage Consents';

  @override
  String get manageConsentsSubtitle => 'Update your GDPR privacy choices';

  @override
  String get exportData => 'Export Data';

  @override
  String get exportDataSubtitle => 'Download a copy of your data';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountSubtitle =>
      'Permanently delete your account and data';

  @override
  String get sync => 'Sync';

  @override
  String get syncStatus => 'Sync Status';

  @override
  String get syncIdle => 'Last synced recently';

  @override
  String get syncError => 'Sync failed. Tap to retry.';

  @override
  String get syncNow => 'Sync Now';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get licenses => 'Open Source Licenses';

  @override
  String get exportStarted => 'Export started...';

  @override
  String get deleteAccountDialogTitle => 'Delete Account?';

  @override
  String get deleteAccountDialogMessage =>
      'This action cannot be undone. All your data will be permanently deleted.';

  @override
  String get deleteAccountRequested => 'Account deletion requested.';

  @override
  String get defaultUser => 'User';

  @override
  String get noEmail => 'No email';

  @override
  String errorLoadingProfile(Object error) {
    return 'Error loading profile: $error';
  }

  @override
  String get logOut => 'Log Out';

  @override
  String get workouts => 'Workouts';

  @override
  String get getStarted => 'Loslegen';

  @override
  String get next => 'Weiter';

  @override
  String get welcomeTitle => 'Welcome to VitalSynch';

  @override
  String get welcomeSubtitle => 'Manage your health and fitness in one place.';

  @override
  String get personalizationTitle => 'What matters most to you?';

  @override
  String get interestMedication => 'Medication Tracking';

  @override
  String get interestFitness => 'Fitness & Workouts';

  @override
  String get interestInsights => 'Smart Insights';

  @override
  String get interestAnalysis => 'Progress Analysis';

  @override
  String get quickSetupTitle => 'Quick Setup';

  @override
  String get quickSetupSubtitle =>
      'Get a head start by adding your first item.';

  @override
  String get quickAddMedication => 'Add Medication';

  @override
  String get quickAddMedicationSubtitle => 'Set up name & time quickly';

  @override
  String get quickPickTemplate => 'Pick Workout Template';

  @override
  String get quickPickTemplateSubtitle => 'Choose from popular routines';

  @override
  String get privacyTitle => 'Your Privacy Matters';

  @override
  String get privacySubtitle =>
      'We believe in transparency. Please review and manage how your data is handled.';

  @override
  String get consentHealthTitle => 'Health Data Processing';

  @override
  String get consentHealthDescription =>
      'Required to track medications and symptoms locally.';

  @override
  String get consentFitnessTitle => 'Fitness Data Processing';

  @override
  String get consentFitnessDescription =>
      'Required to log workouts and track progress locally.';

  @override
  String get consentAnalyticsTitle => 'Analytics & Usage';

  @override
  String get consentAnalyticsDescription =>
      'Help us improve VitalSynch by sharing anonymous usage data.';

  @override
  String get consentBackupTitle => 'Cloud Backup';

  @override
  String get consentBackupDescription =>
      'Securely backup your data to the cloud so you don\'t lose it.';

  @override
  String get readPrivacyPolicy => 'Read Full Privacy Policy';

  @override
  String get acceptContinue => 'Accept & Continue';

  @override
  String get requiredTag => 'REQUIRED';

  @override
  String consentRequiredMessage(String module) {
    return 'This is required for the $module module to function.';
  }

  @override
  String get welcomeBack => 'Willkommen zurück';

  @override
  String get signInSubtitle =>
      'Melden Sie sich an, um Ihre gesunde Reise fortzusetzen';

  @override
  String get email => 'E-Mail';

  @override
  String get password => 'Passwort';

  @override
  String get forgotPassword => 'Passwort vergessen?';

  @override
  String get logIn => 'Anmelden';

  @override
  String get orSeparator => 'ODER';

  @override
  String get continueWithApple => 'Mit Apple fortfahren';

  @override
  String get dontHaveAccount => 'Noch kein Konto?';

  @override
  String get signUp => 'Registrieren';

  @override
  String get enterEmail => 'Bitte geben Sie Ihre E-Mail ein';

  @override
  String get enterPassword => 'Bitte geben Sie Ihr Passwort ein';

  @override
  String loginFailed(Object error) {
    return 'Anmeldung fehlgeschlagen: $error';
  }

  @override
  String appleLoginFailed(Object error) {
    return 'Apple-Anmeldung fehlgeschlagen: $error';
  }

  @override
  String get createAccount => 'Konto erstellen';

  @override
  String get joinVitalSynch => 'Treten Sie VitalSynch heute bei';

  @override
  String get confirmPassword => 'Passwort bestätigen';

  @override
  String get alreadyHaveAccount => 'Haben Sie bereits ein Konto?';

  @override
  String get passwordsDoNotMatch => 'Passwörter stimmen nicht überein';

  @override
  String get passwordLengthError =>
      'Passwort muss mindestens 6 Zeichen lang sein';

  @override
  String get confirmPasswordError => 'Bitte bestätigen Sie Ihr Passwort';

  @override
  String registrationFailed(Object error) {
    return 'Registrierung fehlgeschlagen: $error';
  }

  @override
  String get resetPassword => 'Passwort zurücksetzen';

  @override
  String get resetPasswordSubtitle =>
      'Geben Sie Ihre E-Mail ein, um einen Zurücksetzungslink zu erhalten';

  @override
  String get sendResetLink => 'Zurücksetzungslink senden';

  @override
  String get resetEmailSent =>
      'E-Mail zum Zurücksetzen des Passworts gesendet. Überprüfen Sie Ihren Posteingang.';

  @override
  String resetPasswordError(Object error) {
    return 'Fehler: $error';
  }

  @override
  String get onboardingWelcomeTitle => 'Willkommen bei VitalSynch';

  @override
  String get onboardingWelcomeSubtitle =>
      'Ihr All-in-One-Begleiter für Gesundheit & Fitness';

  @override
  String get onboardingPrivacyNote =>
      'Ihre Daten bleiben auf Ihrem Gerät. Wir respektieren Ihre Privatsphäre.';

  @override
  String get onboardingHealthTitle => 'Verfolgen Sie Ihre Gesundheit';

  @override
  String get onboardingHealthDescription =>
      'Verwalten Sie Medikamente, Symptome und Gesundheitsverlauf';

  @override
  String get onboardingHealthFeature1 =>
      'Verpassen Sie kein Medikament mit intelligenten Erinnerungen';

  @override
  String get onboardingHealthFeature2 =>
      'Protokollieren Sie Symptome und verfolgen Sie Muster';

  @override
  String get onboardingHealthFeature3 =>
      'Sehen Sie Ihren vollständigen Gesundheitsverlauf';

  @override
  String get onboardingFitnessTitle => 'Steigern Sie Ihre Fitness';

  @override
  String get onboardingFitnessDescription =>
      'Protokollieren Sie Workouts, verfolgen Sie Fortschritte, erreichen Sie Ihre Ziele';

  @override
  String get onboardingFitnessFeature1 =>
      'Verfolgen Sie Workouts mit detaillierter Übungsprotokollierung';

  @override
  String get onboardingFitnessFeature2 =>
      'Überwachen Sie Ihren Fortschritt mit visuellen Diagrammen';

  @override
  String get onboardingFitnessFeature3 =>
      'Schalten Sie Erfolge frei und bauen Sie Serien auf';

  @override
  String get onboardingPrivacyTitle => 'Ihre Privatsphäre, Ihre Kontrolle';

  @override
  String get onboardingPrivacyDescription =>
      'Wählen Sie aus, welche Daten Sie teilen möchten';

  @override
  String get onboardingPreferencesTitle => 'Personalisieren Sie Ihre Erfahrung';

  @override
  String get onboardingPreferencesDescription =>
      'Legen Sie Ihre Sprach- und Themenpräferenzen fest';

  @override
  String get onboardingPreferencesNote =>
      'Sie können diese Einstellungen jederzeit ändern';

  @override
  String get gdprAnalyticsTitle => 'Analytik & Einblicke';

  @override
  String get gdprAnalyticsDescription =>
      'Helfen Sie uns, die App mit anonymen Nutzungsdaten zu verbessern';

  @override
  String get gdprHealthDataTitle => 'Gesundheitsdatenspeicherung';

  @override
  String get gdprHealthDataDescription =>
      'Speichern Sie Ihre Medikamenten- und Symptomdaten (erforderlich)';

  @override
  String get gdprFitnessDataTitle => 'Fitnessdatenspeicherung';

  @override
  String get gdprFitnessDataDescription =>
      'Speichern Sie Ihre Workout- und Fortschrittsdaten (erforderlich)';

  @override
  String get gdprCloudBackupTitle => 'Cloud-Backup';

  @override
  String get gdprCloudBackupDescription =>
      'Sichern Sie Ihre Daten in Firebase für die Synchronisierung zwischen Geräten';

  @override
  String get gdprNote =>
      'Erforderliche Zustimmungen sind für die Kernfunktionalität der App notwendig. Sie können Zustimmungen jederzeit in den Einstellungen verwalten.';

  @override
  String get workoutComplete => 'Training Abgeschlossen!';

  @override
  String get greatJob => 'Tolle Arbeit! Weiter so!';

  @override
  String get workoutNotFound => 'Training nicht gefunden';

  @override
  String get done => 'Fertig';

  @override
  String get share => 'Teilen';

  @override
  String get comingSoon => 'Demnächst!';

  @override
  String get volumeChart => 'Volumen Diagramm';

  @override
  String get chartComingSoon => 'Diagramm kommt bald';

  @override
  String get summary => 'Zusammenfassung';

  @override
  String get avgDuration => 'Durchschn. Dauer';

  @override
  String get prsAchieved => 'PRs Erreicht';

  @override
  String get noPRsYet => 'Noch keine persönlichen Rekorde. Weiter so!';

  @override
  String get dismissed => 'Abgelehnt';

  @override
  String get overallWellness => 'Gesamtwellness';

  @override
  String get insightDismissed => 'Einsicht abgelehnt';

  @override
  String get noDismissedInsights => 'Keine abgelehnten Einsichten';

  @override
  String get noInsightsYet => 'Noch keine Einsichten';

  @override
  String get insightsEmptyDescription =>
      'Einsichten werden hier angezeigt, sobald Daten gesammelt werden';

  @override
  String dataCollectedProgress(int collected, int total) {
    return '$collected/$total Tage Daten gesammelt';
  }

  @override
  String errorLoadingInsights(Object error) {
    return 'Fehler beim Laden der Einsichten: $error';
  }

  @override
  String errorLoadingDismissedInsights(Object error) {
    return 'Fehler beim Laden der abgelehnten Einsichten: $error';
  }

  @override
  String get symptomHeadache => 'Kopfschmerzen';

  @override
  String get symptomNausea => 'Übelkeit';

  @override
  String get symptomFatigue => 'Müdigkeit';

  @override
  String get symptomDizziness => 'Schwindel';

  @override
  String get symptomStomachPain => 'Bauchschmerzen';

  @override
  String get symptomBackPain => 'Rückenschmerzen';

  @override
  String get symptomJointPain => 'Gelenkschmerzen';

  @override
  String get symptomInsomnia => 'Schlaflosigkeit';

  @override
  String get symptomAnxiety => 'Angst';

  @override
  String get symptomShortnessOfBreath => 'Atemnot';

  @override
  String get pleaseEnterSymptomName => 'Bitte geben Sie einen Symptomname ein';

  @override
  String get symptomLoggedSuccess => 'Symptom erfolgreich erfasst';

  @override
  String errorLoggingSymptom(Object error) {
    return 'Fehler beim Erfassen des Symptoms: $error';
  }

  @override
  String get severityMild => 'Leicht';

  @override
  String get severityModerate => 'Mäßig';

  @override
  String get severitySevere => 'Schwer';

  @override
  String get severityVerySevere => 'Sehr Schwer';

  @override
  String get severityUnbearable => 'Unerträglich';

  @override
  String get medicationNotFound => 'Medikament nicht gefunden';

  @override
  String errorLoadingMedication(Object error) {
    return 'Fehler beim Laden des Medikaments: $error';
  }

  @override
  String get medicationAddedSuccess => 'Medikament erfolgreich hinzugefügt';

  @override
  String get medicationUpdatedSuccess => 'Medikament erfolgreich aktualisiert';

  @override
  String errorSavingMedication(Object error) {
    return 'Fehler beim Speichern des Medikaments: $error';
  }

  @override
  String get addFirstMedicationButton => 'Erstes Medikament hinzufügen';

  @override
  String get welcomeToHealth => 'Willkommen bei Gesundheit!';

  @override
  String get onboardingHealthMessage =>
      'Beginnen wir damit, Ihr erstes Medikament hinzuzufügen. Die Einhaltung zu verfolgen hilft Ihnen, gesund zu bleiben!';

  @override
  String get weeklyReport => 'Wochenbericht';

  @override
  String errorLoadingReport(Object error) {
    return 'Fehler beim Laden des Berichts: $error';
  }

  @override
  String get taken => 'Eingenommen';

  @override
  String get missed => 'Verpasst';

  @override
  String get skipped => 'Übersprungen';

  @override
  String get volume => 'Volumen';

  @override
  String get healthRing => 'Gesundheit';

  @override
  String get fitnessRing => 'Fitness';

  @override
  String get wellnessRing => 'Wohlbefinden';

  @override
  String get activityRings => 'Aktivitätsringe';

  @override
  String get shareAsInfographic => 'Als Infografik teilen (1080x1920)';

  @override
  String get perfectForStories => 'Ideal für Instagram Stories';

  @override
  String get shareAsCompactCard => 'Als kompakte Karte teilen (1080x1080)';

  @override
  String get perfectForSharing => 'Ideal zum allgemeinen Teilen';

  @override
  String get exportAsJSON => 'Als JSON exportieren';

  @override
  String get gdprDataPortability => 'DSGVO-Datenportabilität';

  @override
  String get generatingImage => 'Bild wird generiert...';

  @override
  String get myWeeklyReport => 'Mein Wochenbericht von VitalSynch';

  @override
  String errorSharing(Object error) {
    return 'Fehler beim Teilen: $error';
  }

  @override
  String get weeklyReportData => 'VitalSynch Wochenbericht-Daten';

  @override
  String get reportExportedAsJSON => 'Bericht als JSON exportiert';

  @override
  String errorExporting(Object error) {
    return 'Fehler beim Exportieren: $error';
  }

  @override
  String get wasThisInsightHelpful => 'War diese Einsicht hilfreich?';

  @override
  String get helpful => 'Hilfreich';

  @override
  String get notHelpful => 'Nicht Hilfreich';

  @override
  String get dismissInsight => 'Einsicht ablehnen';

  @override
  String get thankYouForFeedback => 'Vielen Dank für Ihr Feedback!';

  @override
  String errorSubmittingFeedback(Object error) {
    return 'Fehler beim Senden des Feedbacks: $error';
  }

  @override
  String errorDismissingInsight(Object error) {
    return 'Fehler beim Ablehnen der Einsicht: $error';
  }

  @override
  String get privacyAndData => 'Datenschutz & Daten';

  @override
  String get restTimerSeconds => 'Sekunden';

  @override
  String get skipRestButton => 'Pause überspringen';

  @override
  String get achievementUnlocked => 'Erfolg freigeschaltet!';

  @override
  String errorGeneric(Object error) {
    return 'Fehler: $error';
  }

  @override
  String get healthSummary => 'Gesundheitsübersicht';

  @override
  String get fitnessSummary => 'Fitnessübersicht';

  @override
  String get nextWeekSuggestions => 'Vorschläge für nächste Woche';

  @override
  String get keepUpGreatWork => 'Weiter so, tolle Arbeit!';

  @override
  String vsLastWeekPercent(String percent) {
    return '$percent% vs. letzte Woche';
  }

  @override
  String mostMissed(String timeSlot) {
    return 'Am meisten verpasst: $timeSlot';
  }

  @override
  String bestWorkout(String name, String volume) {
    return 'Bestes Training: $name — ${volume}kg';
  }

  @override
  String get newPersonalRecords => 'Neue persönliche Rekorde';

  @override
  String validUntilDays(int days) {
    return 'Gültig für $days Tage';
  }

  @override
  String validUntilHours(int hours) {
    return 'Gültig für $hours Stunden';
  }

  @override
  String get validUntilSoon => 'Bald ablaufend';

  @override
  String get takeAction => 'Handeln';

  @override
  String errorLoadingInsight(Object error) {
    return 'Fehler beim Laden der Einsicht: $error';
  }

  @override
  String get today => 'Heute';

  @override
  String get yesterday => 'Gestern';

  @override
  String daysAgo(int days) {
    return 'vor $days Tagen';
  }

  @override
  String weeksAgo(int weeks) {
    return 'vor ${weeks}W';
  }

  @override
  String monthsAgo(int months) {
    return 'vor ${months}M';
  }

  @override
  String get loading => 'Laden...';

  @override
  String errorAddingSet(Object error) {
    return 'Fehler beim Hinzufügen des Satzes: $error';
  }

  @override
  String get chartError => 'Diagrammfehler';

  @override
  String get shareFunctionalityComingSoon => 'Teilen-Funktion kommt bald!';

  @override
  String severityLabel(int severity) {
    return 'Schweregrad: $severity';
  }

  @override
  String get errorLoadingCalendar => 'Fehler beim Laden des Kalenders';
}
