// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'VitalSync';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get health => 'Health';

  @override
  String get fitness => 'Fitness';

  @override
  String get settings => 'Settings';

  @override
  String get profile => 'Profile';

  @override
  String get syncOnline => 'Online';

  @override
  String get syncOffline => 'Offline';

  @override
  String get syncing => 'Syncing';

  @override
  String get syncOnlineTooltip => 'Online - Data synced';

  @override
  String get syncOfflineTooltip => 'Offline - Changes will sync when online';

  @override
  String get syncingTooltip => 'Syncing...';

  @override
  String get syncSemanticsOnline => 'Online';

  @override
  String get syncSemanticsOffline => 'Offline';

  @override
  String get syncSemanticsSyncing => 'Syncing data';

  @override
  String get insights => 'Insights';

  @override
  String insightsCountSemantics(int count) {
    return 'Insights, $count unread';
  }

  @override
  String insightsCountTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'insights',
      one: 'insight',
    );
    return '$count new $_temp0';
  }

  @override
  String get addMedication => 'Add Medication';

  @override
  String get logSymptom => 'Log Symptom';

  @override
  String get startWorkout => 'Start Workout';

  @override
  String get quickAddMenuOpen => 'Open quick add menu';

  @override
  String get quickAddMenuClose => 'Close quick add menu';

  @override
  String get dashboardTabSemantics => 'Dashboard tab';

  @override
  String get dashboardTabSelectedSemantics => 'Dashboard tab, selected';

  @override
  String get dashboardTabTooltip =>
      'View your unified health and fitness dashboard';

  @override
  String get healthTabSemantics => 'Health tab';

  @override
  String get healthTabSelectedSemantics => 'Health tab, selected';

  @override
  String get healthTabTooltip => 'Manage medications and symptoms';

  @override
  String get fitnessTabSemantics => 'Fitness tab';

  @override
  String get fitnessTabSelectedSemantics => 'Fitness tab, selected';

  @override
  String get fitnessTabTooltip => 'Track workouts and progress';

  @override
  String get settingsSemantics => 'Settings';

  @override
  String get settingsTooltip => 'Open settings';

  @override
  String get profileSemantics => 'Profile';

  @override
  String get returnToWorkout => 'Return to Workout';

  @override
  String get timeElapsed => 'Time elapsed';

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String get goodNight => 'Good night';

  @override
  String get todaysMedications => 'Today\'s Medications';

  @override
  String nextMedicationIn(Object time) {
    return 'Next in $time';
  }

  @override
  String get noUpcomingMedications => 'No upcoming medications';

  @override
  String get hoursShort => 'h';

  @override
  String get minutesShort => 'm';

  @override
  String get currentStreak => 'day streak';

  @override
  String get inProgress => 'In progress';

  @override
  String get weeklyOverview => 'Weekly Overview';

  @override
  String get thisWeek => 'This Week';

  @override
  String get last30Days => 'Last 30 Days';

  @override
  String get medicationCompliance => 'Medication';

  @override
  String get workoutVolume => 'Workout';

  @override
  String get viewReport => 'View Report';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get viewAll => 'View All';

  @override
  String get noRecentActivity => 'No recent activity';

  @override
  String get dataCollecting => 'Insights will appear here as data is collected';

  @override
  String get startFirstWorkout => 'Start your first workout';

  @override
  String get addFirstMedication => 'Add your first medication';

  @override
  String get dismissInsightTitle => 'Dismiss Insight';

  @override
  String get dismissInsightMessage =>
      'Are you sure you want to dismiss this insight?';

  @override
  String get cancel => 'Cancel';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get errorLoadingDashboard => 'Error loading dashboard';

  @override
  String get retry => 'Retry';

  @override
  String get active => 'Active';

  @override
  String get all => 'All';

  @override
  String get completed => 'Completed';

  @override
  String get searchMedication => 'Search medication...';

  @override
  String get noMedicationsFound => 'No medications found';

  @override
  String get editMedication => 'Edit Medication';

  @override
  String get exerciseName => 'Exercise Name';

  @override
  String get medicationName => 'Medication Name';

  @override
  String get dosage => 'Dosage';

  @override
  String get requiredField => 'This field is required';

  @override
  String get frequency => 'Frequency';

  @override
  String get scheduledTimes => 'Scheduled Times';

  @override
  String get color => 'Color';

  @override
  String get saving => 'Saving...';

  @override
  String get save => 'Save';

  @override
  String get medicationDetails => 'Medication Details';

  @override
  String get deleteMedication => 'Delete Medication';

  @override
  String get deleteConfirmation =>
      'Are you sure you want to delete this medication?';

  @override
  String get delete => 'Delete';

  @override
  String get complianceHistory => 'Compliance History';

  @override
  String get history => 'History';

  @override
  String get noLogsYet => 'No logs yet';

  @override
  String get takenAt => 'Taken at';

  @override
  String get shareReport => 'Share Report';

  @override
  String get symptoms => 'Symptoms';

  @override
  String get mostFrequent => 'Most Frequent';

  @override
  String get recentTimeline => 'Recent Timeline';

  @override
  String get noSymptomsLogged => 'No symptoms logged';

  @override
  String get symptomName => 'Symptom Name';

  @override
  String get severity => 'Severity';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';

  @override
  String get notes => 'Notes';

  @override
  String get healthTimeline => 'Health Timeline';

  @override
  String get compliance => 'Compliance';

  @override
  String get medications => 'Medications';

  @override
  String get complianceTrend => 'Compliance Trend';

  @override
  String get skip => 'Skip';

  @override
  String get take => 'Take';

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

  @override
  String get noExercises => 'No exercises in this workout';

  @override
  String get muscleGroup => 'Muscle Group';

  @override
  String get equipment => 'Equipment';

  @override
  String get exerciseAdded => 'Exercise added successfully';
}
