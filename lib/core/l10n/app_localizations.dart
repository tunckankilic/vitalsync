import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('tr'),
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'VitalSync'**
  String get appTitle;

  /// Dashboard tab label
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// Health tab label
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get health;

  /// Fitness tab label
  ///
  /// In en, this message translates to:
  /// **'Fitness'**
  String get fitness;

  /// Settings button label
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Profile button label
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Sync status: online
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get syncOnline;

  /// Sync status: offline
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get syncOffline;

  /// Sync status: syncing
  ///
  /// In en, this message translates to:
  /// **'Syncing'**
  String get syncing;

  /// Tooltip for online sync status
  ///
  /// In en, this message translates to:
  /// **'Online - Data synced'**
  String get syncOnlineTooltip;

  /// Tooltip for offline sync status
  ///
  /// In en, this message translates to:
  /// **'Offline - Changes will sync when online'**
  String get syncOfflineTooltip;

  /// Tooltip for syncing status
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncingTooltip;

  /// Semantics label for online status
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get syncSemanticsOnline;

  /// Semantics label for offline status
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get syncSemanticsOffline;

  /// Semantics label for syncing status
  ///
  /// In en, this message translates to:
  /// **'Syncing data'**
  String get syncSemanticsSyncing;

  /// Insights label
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insights;

  /// Semantics label for insights count
  ///
  /// In en, this message translates to:
  /// **'Insights, {count} unread'**
  String insightsCountSemantics(int count);

  /// Tooltip for insights count
  ///
  /// In en, this message translates to:
  /// **'{count} new {count, plural, =1{insight} other{insights}}'**
  String insightsCountTooltip(int count);

  /// Add medication button label
  ///
  /// In en, this message translates to:
  /// **'Add Medication'**
  String get addMedication;

  /// Log symptom button label
  ///
  /// In en, this message translates to:
  /// **'Log Symptom'**
  String get logSymptom;

  /// Start workout button label
  ///
  /// In en, this message translates to:
  /// **'Start Workout'**
  String get startWorkout;

  /// Semantics label for opening quick add menu
  ///
  /// In en, this message translates to:
  /// **'Open quick add menu'**
  String get quickAddMenuOpen;

  /// Semantics label for closing quick add menu
  ///
  /// In en, this message translates to:
  /// **'Close quick add menu'**
  String get quickAddMenuClose;

  /// Semantics label for dashboard tab
  ///
  /// In en, this message translates to:
  /// **'Dashboard tab'**
  String get dashboardTabSemantics;

  /// Semantics label for selected dashboard tab
  ///
  /// In en, this message translates to:
  /// **'Dashboard tab, selected'**
  String get dashboardTabSelectedSemantics;

  /// Tooltip for dashboard tab
  ///
  /// In en, this message translates to:
  /// **'View your unified health and fitness dashboard'**
  String get dashboardTabTooltip;

  /// Semantics label for health tab
  ///
  /// In en, this message translates to:
  /// **'Health tab'**
  String get healthTabSemantics;

  /// Semantics label for selected health tab
  ///
  /// In en, this message translates to:
  /// **'Health tab, selected'**
  String get healthTabSelectedSemantics;

  /// Tooltip for health tab
  ///
  /// In en, this message translates to:
  /// **'Manage medications and symptoms'**
  String get healthTabTooltip;

  /// Semantics label for fitness tab
  ///
  /// In en, this message translates to:
  /// **'Fitness tab'**
  String get fitnessTabSemantics;

  /// Semantics label for selected fitness tab
  ///
  /// In en, this message translates to:
  /// **'Fitness tab, selected'**
  String get fitnessTabSelectedSemantics;

  /// Tooltip for fitness tab
  ///
  /// In en, this message translates to:
  /// **'Track workouts and progress'**
  String get fitnessTabTooltip;

  /// Semantics label for settings button
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsSemantics;

  /// Tooltip for settings button
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get settingsTooltip;

  /// Semantics label for profile button
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileSemantics;

  /// Active workout mini-bar label
  ///
  /// In en, this message translates to:
  /// **'Return to Workout'**
  String get returnToWorkout;

  /// Time elapsed label for workout
  ///
  /// In en, this message translates to:
  /// **'Time elapsed'**
  String get timeElapsed;

  /// Morning greeting
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// Afternoon greeting
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// Evening greeting
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// Night greeting
  ///
  /// In en, this message translates to:
  /// **'Good night'**
  String get goodNight;

  /// Today's medications label
  ///
  /// In en, this message translates to:
  /// **'Today\'s Medications'**
  String get todaysMedications;

  /// Next medication time with placeholder
  ///
  /// In en, this message translates to:
  /// **'Next in {time}'**
  String nextMedicationIn(Object time);

  /// No upcoming medications message
  ///
  /// In en, this message translates to:
  /// **'No upcoming medications'**
  String get noUpcomingMedications;

  /// Hours abbreviation
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get hoursShort;

  /// Minutes abbreviation
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get minutesShort;

  /// Current streak label
  ///
  /// In en, this message translates to:
  /// **'day streak'**
  String get currentStreak;

  /// In progress status
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get inProgress;

  /// Weekly overview chart title
  ///
  /// In en, this message translates to:
  /// **'Weekly Overview'**
  String get weeklyOverview;

  /// This week filter
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// Last 30 days filter
  ///
  /// In en, this message translates to:
  /// **'Last 30 Days'**
  String get last30Days;

  /// Medication compliance label
  ///
  /// In en, this message translates to:
  /// **'Medication'**
  String get medicationCompliance;

  /// Workout volume label
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get workoutVolume;

  /// View report button label
  ///
  /// In en, this message translates to:
  /// **'View Report'**
  String get viewReport;

  /// Recent activity section title
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// View all link
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No recent activity message
  ///
  /// In en, this message translates to:
  /// **'No recent activity'**
  String get noRecentActivity;

  /// Data collecting message for empty insights
  ///
  /// In en, this message translates to:
  /// **'Insights will appear here as data is collected'**
  String get dataCollecting;

  /// Start first workout CTA
  ///
  /// In en, this message translates to:
  /// **'Start your first workout'**
  String get startFirstWorkout;

  /// Add first medication CTA
  ///
  /// In en, this message translates to:
  /// **'Add your first medication'**
  String get addFirstMedication;

  /// Dismiss insight dialog title
  ///
  /// In en, this message translates to:
  /// **'Dismiss Insight'**
  String get dismissInsightTitle;

  /// Dismiss insight confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to dismiss this insight?'**
  String get dismissInsightMessage;

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Dismiss button
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// Error loading dashboard message
  ///
  /// In en, this message translates to:
  /// **'Error loading dashboard'**
  String get errorLoadingDashboard;

  /// Retry button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Active filter tab
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// All filter tab
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// Completed filter tab
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// Search medication hint
  ///
  /// In en, this message translates to:
  /// **'Search medication...'**
  String get searchMedication;

  /// No medications found message
  ///
  /// In en, this message translates to:
  /// **'No medications found'**
  String get noMedicationsFound;

  /// Edit medication title
  ///
  /// In en, this message translates to:
  /// **'Edit Medication'**
  String get editMedication;

  /// Exercise name label
  ///
  /// In en, this message translates to:
  /// **'Exercise Name'**
  String get exerciseName;

  /// Medication name label
  ///
  /// In en, this message translates to:
  /// **'Medication Name'**
  String get medicationName;

  /// Dosage label
  ///
  /// In en, this message translates to:
  /// **'Dosage'**
  String get dosage;

  /// Required field error
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredField;

  /// Frequency label
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// Scheduled times label
  ///
  /// In en, this message translates to:
  /// **'Scheduled Times'**
  String get scheduledTimes;

  /// Color label
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// Saving status
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// Save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Medication details title
  ///
  /// In en, this message translates to:
  /// **'Medication Details'**
  String get medicationDetails;

  /// Delete medication title
  ///
  /// In en, this message translates to:
  /// **'Delete Medication'**
  String get deleteMedication;

  /// Delete confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this medication?'**
  String get deleteConfirmation;

  /// Delete button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Compliance history title
  ///
  /// In en, this message translates to:
  /// **'Compliance History'**
  String get complianceHistory;

  /// History title
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No logs message
  ///
  /// In en, this message translates to:
  /// **'No logs yet'**
  String get noLogsYet;

  /// Taken at label
  ///
  /// In en, this message translates to:
  /// **'Taken at'**
  String get takenAt;

  /// Share report button
  ///
  /// In en, this message translates to:
  /// **'Share Report'**
  String get shareReport;

  /// Symptoms title
  ///
  /// In en, this message translates to:
  /// **'Symptoms'**
  String get symptoms;

  /// Most frequent section title
  ///
  /// In en, this message translates to:
  /// **'Most Frequent'**
  String get mostFrequent;

  /// Recent timeline section title
  ///
  /// In en, this message translates to:
  /// **'Recent Timeline'**
  String get recentTimeline;

  /// No symptoms logged message
  ///
  /// In en, this message translates to:
  /// **'No symptoms logged'**
  String get noSymptomsLogged;

  /// Symptom name label
  ///
  /// In en, this message translates to:
  /// **'Symptom Name'**
  String get symptomName;

  /// Severity label
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get severity;

  /// Date label
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// Time label
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// Notes label
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// Health timeline title
  ///
  /// In en, this message translates to:
  /// **'Health Timeline'**
  String get healthTimeline;

  /// Compliance label
  ///
  /// In en, this message translates to:
  /// **'Compliance'**
  String get compliance;

  /// Medications label
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get medications;

  /// Compliance trend label
  ///
  /// In en, this message translates to:
  /// **'Compliance Trend'**
  String get complianceTrend;

  /// Skip button
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// Take button
  ///
  /// In en, this message translates to:
  /// **'Take'**
  String get take;

  /// Workout home screen title
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get workoutHome;

  /// Recent workouts section title
  ///
  /// In en, this message translates to:
  /// **'Recent Workouts'**
  String get recentWorkouts;

  /// Workout templates section title
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get workoutTemplates;

  /// Create new template button
  ///
  /// In en, this message translates to:
  /// **'Create New Template'**
  String get createNewTemplate;

  /// Quick stats section title
  ///
  /// In en, this message translates to:
  /// **'Quick Stats'**
  String get quickStats;

  /// This week's volume label
  ///
  /// In en, this message translates to:
  /// **'This Week\'s Volume'**
  String get thisWeeksVolume;

  /// This week's workouts count label
  ///
  /// In en, this message translates to:
  /// **'This Week\'s Workouts'**
  String get thisWeeksWorkouts;

  /// Comparison to last week label
  ///
  /// In en, this message translates to:
  /// **'vs last week'**
  String get vsLastWeek;

  /// Active workout screen title
  ///
  /// In en, this message translates to:
  /// **'Active Workout'**
  String get activeWorkout;

  /// Finish workout button
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finishWorkout;

  /// Discard workout dialog title
  ///
  /// In en, this message translates to:
  /// **'Discard Workout'**
  String get discardWorkout;

  /// Discard workout confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure? Your workout won\'t be saved.'**
  String get discardWorkoutMessage;

  /// Previous session label
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previousSession;

  /// Set number label
  ///
  /// In en, this message translates to:
  /// **'Set {number}'**
  String setNumber(int number);

  /// Weight label
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// Reps label
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get reps;

  /// Warmup toggle label
  ///
  /// In en, this message translates to:
  /// **'Warmup'**
  String get warmup;

  /// Complete set button
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get completeSet;

  /// Rest timer label
  ///
  /// In en, this message translates to:
  /// **'Rest Timer'**
  String get restTimer;

  /// Skip rest button
  ///
  /// In en, this message translates to:
  /// **'Skip Rest'**
  String get skipRest;

  /// Ready for next set prompt
  ///
  /// In en, this message translates to:
  /// **'Ready for next set?'**
  String get readyForNextSet;

  /// Add exercise button
  ///
  /// In en, this message translates to:
  /// **'Add Exercise'**
  String get addExercise;

  /// Seconds unit
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get seconds;

  /// Workout summary screen title
  ///
  /// In en, this message translates to:
  /// **'Workout Summary'**
  String get workoutSummary;

  /// Duration label
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// Total volume label
  ///
  /// In en, this message translates to:
  /// **'Total Volume'**
  String get totalVolume;

  /// Total sets label
  ///
  /// In en, this message translates to:
  /// **'Total Sets'**
  String get totalSets;

  /// Exercise count label
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get exerciseCount;

  /// New personal records section title
  ///
  /// In en, this message translates to:
  /// **'New PRs'**
  String get newPRs;

  /// Rate workout label
  ///
  /// In en, this message translates to:
  /// **'Rate Your Workout'**
  String get rateWorkout;

  /// Workout notes label
  ///
  /// In en, this message translates to:
  /// **'Workout Notes'**
  String get workoutNotes;

  /// Share workout button
  ///
  /// In en, this message translates to:
  /// **'Share Workout'**
  String get shareWorkout;

  /// Story format share option
  ///
  /// In en, this message translates to:
  /// **'Story Format'**
  String get storyFormat;

  /// Compact card share option
  ///
  /// In en, this message translates to:
  /// **'Compact Card'**
  String get compactCard;

  /// Export JSON option
  ///
  /// In en, this message translates to:
  /// **'Export JSON'**
  String get exportJSON;

  /// Share template watermark
  ///
  /// In en, this message translates to:
  /// **'Tracked with VitalSync'**
  String get trackedWithVitalSync;

  /// Exercise library screen title
  ///
  /// In en, this message translates to:
  /// **'Exercise Library'**
  String get exerciseLibrary;

  /// Search exercises hint
  ///
  /// In en, this message translates to:
  /// **'Search exercises...'**
  String get searchExercises;

  /// All categories filter
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allCategories;

  /// Chest muscle group
  ///
  /// In en, this message translates to:
  /// **'Chest'**
  String get chest;

  /// Back muscle group
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Shoulders muscle group
  ///
  /// In en, this message translates to:
  /// **'Shoulders'**
  String get shoulders;

  /// Arms muscle group
  ///
  /// In en, this message translates to:
  /// **'Arms'**
  String get arms;

  /// Legs muscle group
  ///
  /// In en, this message translates to:
  /// **'Legs'**
  String get legs;

  /// Core muscle group
  ///
  /// In en, this message translates to:
  /// **'Core'**
  String get core;

  /// Cardio category
  ///
  /// In en, this message translates to:
  /// **'Cardio'**
  String get cardio;

  /// Exercise details title
  ///
  /// In en, this message translates to:
  /// **'Exercise Details'**
  String get exerciseDetails;

  /// Instructions label
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get instructions;

  /// Exercise history label
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get exerciseHistory;

  /// Personal record label
  ///
  /// In en, this message translates to:
  /// **'Personal Record'**
  String get personalRecord;

  /// Weight progression chart title
  ///
  /// In en, this message translates to:
  /// **'Weight Progression'**
  String get weightProgression;

  /// Create custom exercise button
  ///
  /// In en, this message translates to:
  /// **'Create Custom Exercise'**
  String get createCustomExercise;

  /// Progress screen title
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// One week time range
  ///
  /// In en, this message translates to:
  /// **'1W'**
  String get oneWeek;

  /// One month time range
  ///
  /// In en, this message translates to:
  /// **'1M'**
  String get oneMonth;

  /// Three months time range
  ///
  /// In en, this message translates to:
  /// **'3M'**
  String get threeMonths;

  /// Six months time range
  ///
  /// In en, this message translates to:
  /// **'6M'**
  String get sixMonths;

  /// One year time range
  ///
  /// In en, this message translates to:
  /// **'1Y'**
  String get oneYear;

  /// Volume progression chart title
  ///
  /// In en, this message translates to:
  /// **'Volume Progression'**
  String get volumeProgression;

  /// Workout frequency section title
  ///
  /// In en, this message translates to:
  /// **'Workout Frequency'**
  String get workoutFrequency;

  /// Personal records section title
  ///
  /// In en, this message translates to:
  /// **'Personal Records'**
  String get personalRecords;

  /// One rep max abbreviation
  ///
  /// In en, this message translates to:
  /// **'1RM'**
  String get oneRepMax;

  /// Select exercise dropdown hint
  ///
  /// In en, this message translates to:
  /// **'Select Exercise'**
  String get selectExercise;

  /// Calendar screen title
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// Monthly stats section title
  ///
  /// In en, this message translates to:
  /// **'Monthly Stats'**
  String get monthlyStats;

  /// Total workouts label
  ///
  /// In en, this message translates to:
  /// **'Total Workouts'**
  String get totalWorkouts;

  /// Streak label
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streak;

  /// Comparison to previous month label
  ///
  /// In en, this message translates to:
  /// **'vs previous month'**
  String get vsPreviousMonth;

  /// Workout details title
  ///
  /// In en, this message translates to:
  /// **'Workout Details'**
  String get workoutDetails;

  /// Achievements screen title
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// Unlocked achievement status
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get unlocked;

  /// Locked achievement status
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked;

  /// Near completion message
  ///
  /// In en, this message translates to:
  /// **'Almost there!'**
  String get nearCompletion;

  /// Achievement progress format
  ///
  /// In en, this message translates to:
  /// **'{current} / {total}'**
  String achievementProgress(int current, int total);

  /// Fitness category
  ///
  /// In en, this message translates to:
  /// **'Fitness'**
  String get fitnessCategory;

  /// Health category
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get healthCategory;

  /// Cross-module category
  ///
  /// In en, this message translates to:
  /// **'Cross-Module'**
  String get crossModuleCategory;

  /// Template name label
  ///
  /// In en, this message translates to:
  /// **'Template Name'**
  String get templateName;

  /// Estimated duration label
  ///
  /// In en, this message translates to:
  /// **'Estimated Duration'**
  String get estimatedDuration;

  /// Exercises label
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get exercises;

  /// Edit template button
  ///
  /// In en, this message translates to:
  /// **'Edit Template'**
  String get editTemplate;

  /// Delete template button
  ///
  /// In en, this message translates to:
  /// **'Delete Template'**
  String get deleteTemplate;

  /// Delete template confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this template?'**
  String get deleteTemplateConfirmation;

  /// Sets label
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get sets;

  /// Rest time label
  ///
  /// In en, this message translates to:
  /// **'Rest Time'**
  String get restTime;

  /// Add exercise to template button
  ///
  /// In en, this message translates to:
  /// **'Add Exercise'**
  String get addExerciseToTemplate;

  /// No workouts empty state
  ///
  /// In en, this message translates to:
  /// **'No workouts yet'**
  String get noWorkoutsYet;

  /// Start first workout message
  ///
  /// In en, this message translates to:
  /// **'Start your first workout to begin tracking your progress'**
  String get startYourFirstWorkout;

  /// No templates empty state
  ///
  /// In en, this message translates to:
  /// **'No templates yet'**
  String get noTemplatesYet;

  /// Create first template message
  ///
  /// In en, this message translates to:
  /// **'Create a template to quickly start workouts'**
  String get createYourFirstTemplate;

  /// No exercises found message
  ///
  /// In en, this message translates to:
  /// **'No exercises found'**
  String get noExercisesFound;

  /// No achievements empty state
  ///
  /// In en, this message translates to:
  /// **'No achievements yet'**
  String get noAchievementsYet;

  /// Keep working message
  ///
  /// In en, this message translates to:
  /// **'Keep working out to unlock achievements'**
  String get keepWorkingToUnlock;

  /// First workout completion message
  ///
  /// In en, this message translates to:
  /// **'First workout complete! 🔥'**
  String get firstWorkoutComplete;

  /// Consistency motivation message
  ///
  /// In en, this message translates to:
  /// **'Consistency is key! Keep your streak going'**
  String get consistencyIsKey;

  /// New PR celebration message
  ///
  /// In en, this message translates to:
  /// **'New Personal Record! 🏆'**
  String get newPRCelebration;

  /// Share PR call to action
  ///
  /// In en, this message translates to:
  /// **'Share your achievement'**
  String get shareYourPR;

  /// Streak milestone message
  ///
  /// In en, this message translates to:
  /// **'{days} Day Streak! 🔥'**
  String streakMilestone(int days);

  /// Share streak prompt
  ///
  /// In en, this message translates to:
  /// **'Share your streak?'**
  String get shareYourStreak;

  /// Kilograms unit
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get kg;

  /// Pounds unit
  ///
  /// In en, this message translates to:
  /// **'lbs'**
  String get lbs;

  /// Minutes abbreviation
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get min;

  /// No exercises found in workout session
  ///
  /// In en, this message translates to:
  /// **'No exercises in this workout'**
  String get noExercises;

  /// Muscle group label
  ///
  /// In en, this message translates to:
  /// **'Muscle Group'**
  String get muscleGroup;

  /// Equipment label
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get equipment;

  /// Exercise added success message
  ///
  /// In en, this message translates to:
  /// **'Exercise added successfully'**
  String get exerciseAdded;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
