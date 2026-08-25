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

  /// Dashboard health score card title
  ///
  /// In en, this message translates to:
  /// **'Health score'**
  String get healthScore;

  /// Dashboard streak stat label
  ///
  /// In en, this message translates to:
  /// **'Day streak'**
  String get dayStreak;

  /// Dashboard today's medications card title
  ///
  /// In en, this message translates to:
  /// **'Today\'s medications'**
  String get todayMedications;

  /// Ratio of medication doses taken today
  ///
  /// In en, this message translates to:
  /// **'{taken}/{total} taken'**
  String dosesTakenRatio(int taken, int total);

  /// Caption under the dashboard health score
  ///
  /// In en, this message translates to:
  /// **'{percent}% — 7-day medication compliance'**
  String healthScoreCaption(int percent);

  /// Empty state for today's medications
  ///
  /// In en, this message translates to:
  /// **'No medications scheduled for today.'**
  String get noMedicationsToday;

  /// Dashboard load error title
  ///
  /// In en, this message translates to:
  /// **'Could not load dashboard'**
  String get dashboardLoadError;

  /// Hint to pull-to-refresh after an error
  ///
  /// In en, this message translates to:
  /// **'Pull down to retry.'**
  String get pullToRetry;

  /// Splash init error dialog title
  ///
  /// In en, this message translates to:
  /// **'Initialization Error'**
  String get initializationError;

  /// Splash init error dialog body
  ///
  /// In en, this message translates to:
  /// **'The app could not start properly. Please check your internet connection and try again.\n\nDetails: {error}'**
  String initializationErrorBody(Object error);

  /// Splash init error continue button
  ///
  /// In en, this message translates to:
  /// **'Continue Anyway'**
  String get continueAnyway;

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'VitalSynch'**
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

  /// Semantics label for sync error status
  ///
  /// In en, this message translates to:
  /// **'Sync error'**
  String get syncSemanticsError;

  /// Tooltip for sync error status
  ///
  /// In en, this message translates to:
  /// **'Sync error - tap to retry'**
  String get syncErrorTooltip;

  /// Shown when a manual sync is blocked by missing cloud backup consent
  ///
  /// In en, this message translates to:
  /// **'Turn on Cloud Backup in Privacy & Data to sync'**
  String get syncNeedsCloudConsent;

  /// Shown when a manual sync is blocked because no user is signed in
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync your data'**
  String get syncNeedsSignIn;

  /// Shown when a manual sync finishes successfully
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get syncCompleted;

  /// Shown when a manual sync throws an error
  ///
  /// In en, this message translates to:
  /// **'Sync failed. Please try again.'**
  String get syncFailed;

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

  /// Achievement category covering both medication and workouts
  ///
  /// In en, this message translates to:
  /// **'Consistency'**
  String get consistency;

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

  /// Acknowledge button for the health disclaimer
  ///
  /// In en, this message translates to:
  /// **'I understand'**
  String get understood;

  /// Title for the medical/health disclaimer
  ///
  /// In en, this message translates to:
  /// **'Health Disclaimer'**
  String get healthDisclaimerTitle;

  /// Settings subtitle for the health disclaimer
  ///
  /// In en, this message translates to:
  /// **'Important medical information'**
  String get healthDisclaimerSubtitle;

  /// Full medical/health disclaimer text
  ///
  /// In en, this message translates to:
  /// **'VitalSynch is designed to help you track your medications, symptoms, and workouts. It is not a medical device and does not provide medical advice, diagnosis, or treatment. Always consult a qualified healthcare professional before making decisions about your health, medications, or exercise. Never disregard professional medical advice because of something you have read in this app. In case of a medical emergency, contact your local emergency services immediately.'**
  String get healthDisclaimerBody;

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

  /// Default name for a workout session started without a template
  ///
  /// In en, this message translates to:
  /// **'Quick Workout'**
  String get quickWorkout;

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
  /// **'Tracked with VitalSynch'**
  String get trackedWithVitalSynch;

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

  /// Back button
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

  /// Workout frequency chart title
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

  /// Edit profile screen title
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// User not found error
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get userNotFound;

  /// Personal information section title
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// Full name label
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// Enter full name validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get enterFullName;

  /// Name too short validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter at least 2 characters'**
  String get nameTooShort;

  /// Date of birth label
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// Select date placeholder
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// Gender label
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// Male gender option
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// Female gender option
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// Other gender option
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get genderOther;

  /// Prefer not to say gender option
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get genderPreferNotToSay;

  /// Emergency contact section title
  ///
  /// In en, this message translates to:
  /// **'Emergency Contact'**
  String get emergencyContact;

  /// Contact name label
  ///
  /// In en, this message translates to:
  /// **'Contact Name'**
  String get contactName;

  /// Phone number label
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// Save changes button
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// Profile updated success message
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccess;

  /// Profile update error message
  ///
  /// In en, this message translates to:
  /// **'Error updating profile: {error}'**
  String profileUpdateError(Object error);

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Appearance settings section
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// Theme label
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// System theme option
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// Light theme option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Dark theme option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Material You setting
  ///
  /// In en, this message translates to:
  /// **'Material You'**
  String get materialYou;

  /// Material You setting subtitle
  ///
  /// In en, this message translates to:
  /// **'Use dynamic colors from wallpaper'**
  String get materialYouSubtitle;

  /// Language label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEn;

  /// Turkish language option
  ///
  /// In en, this message translates to:
  /// **'Türkçe'**
  String get languageTr;

  /// German language option
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get languageDe;

  /// Notifications settings section
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Enable notifications toggle
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// Units settings section
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get units;

  /// Unit system setting
  ///
  /// In en, this message translates to:
  /// **'Unit System'**
  String get unitSystem;

  /// Metric unit option
  ///
  /// In en, this message translates to:
  /// **'Metric (kg, cm)'**
  String get unitMetric;

  /// Imperial unit option
  ///
  /// In en, this message translates to:
  /// **'Imperial (lbs, in)'**
  String get unitImperial;

  /// Privacy and data settings section
  ///
  /// In en, this message translates to:
  /// **'Privacy & Data'**
  String get privacyData;

  /// Manage consents setting
  ///
  /// In en, this message translates to:
  /// **'Manage Consents'**
  String get manageConsents;

  /// Manage consents subtitle
  ///
  /// In en, this message translates to:
  /// **'Update your GDPR privacy choices'**
  String get manageConsentsSubtitle;

  /// Export data setting
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// Export data subtitle
  ///
  /// In en, this message translates to:
  /// **'Download a copy of your data'**
  String get exportDataSubtitle;

  /// Delete account setting
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// Delete account subtitle
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account and data'**
  String get deleteAccountSubtitle;

  /// Sync settings section
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// Sync status setting
  ///
  /// In en, this message translates to:
  /// **'Sync Status'**
  String get syncStatus;

  /// Sync idle status
  ///
  /// In en, this message translates to:
  /// **'Last synced recently'**
  String get syncIdle;

  /// Sync error status
  ///
  /// In en, this message translates to:
  /// **'Sync failed. Tap to retry.'**
  String get syncError;

  /// Sync now button
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// About settings section
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Version label
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Licenses label
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get licenses;

  /// Export started message
  ///
  /// In en, this message translates to:
  /// **'Export started...'**
  String get exportStarted;

  /// Delete account dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Account?'**
  String get deleteAccountDialogTitle;

  /// Delete account dialog message
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. All your data will be permanently deleted.'**
  String get deleteAccountDialogMessage;

  /// Delete account requested message
  ///
  /// In en, this message translates to:
  /// **'Account deletion requested.'**
  String get deleteAccountRequested;

  /// Shown when the user tries to delete their account while offline
  ///
  /// In en, this message translates to:
  /// **'You must be online to delete your account. Please connect to the internet and try again.'**
  String get deleteAccountOnlineRequired;

  /// Shown when account deletion fails
  ///
  /// In en, this message translates to:
  /// **'Account deletion failed. Your data was not deleted. Please try again.'**
  String get deleteAccountFailed;

  /// Default user name
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get defaultUser;

  /// No email placeholder
  ///
  /// In en, this message translates to:
  /// **'No email'**
  String get noEmail;

  /// Error loading profile message
  ///
  /// In en, this message translates to:
  /// **'Error loading profile: {error}'**
  String errorLoadingProfile(Object error);

  /// Log out button
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// Log out confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logOutConfirmTitle;

  /// Log out confirmation dialog message
  ///
  /// In en, this message translates to:
  /// **'You\'ll need to sign in again to access your account.'**
  String get logOutConfirmMessage;

  /// Workouts stat label
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get workouts;

  /// Get started button
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// Next button
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Welcome screen title
  ///
  /// In en, this message translates to:
  /// **'Welcome to VitalSynch'**
  String get welcomeTitle;

  /// Welcome screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Manage your health and fitness in one place.'**
  String get welcomeSubtitle;

  /// Personalization screen title
  ///
  /// In en, this message translates to:
  /// **'What matters most to you?'**
  String get personalizationTitle;

  /// Medication interest
  ///
  /// In en, this message translates to:
  /// **'Medication Tracking'**
  String get interestMedication;

  /// Fitness interest
  ///
  /// In en, this message translates to:
  /// **'Fitness & Workouts'**
  String get interestFitness;

  /// Insights interest
  ///
  /// In en, this message translates to:
  /// **'Smart Insights'**
  String get interestInsights;

  /// Analysis interest
  ///
  /// In en, this message translates to:
  /// **'Progress Analysis'**
  String get interestAnalysis;

  /// Quick setup screen title
  ///
  /// In en, this message translates to:
  /// **'Quick Setup'**
  String get quickSetupTitle;

  /// Quick setup screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Get a head start by adding your first item.'**
  String get quickSetupSubtitle;

  /// Quick add medication option
  ///
  /// In en, this message translates to:
  /// **'Add Medication'**
  String get quickAddMedication;

  /// Quick add medication subtitle
  ///
  /// In en, this message translates to:
  /// **'Set up name & time quickly'**
  String get quickAddMedicationSubtitle;

  /// Quick pick template option
  ///
  /// In en, this message translates to:
  /// **'Pick Workout Template'**
  String get quickPickTemplate;

  /// Quick pick template subtitle
  ///
  /// In en, this message translates to:
  /// **'Choose from popular routines'**
  String get quickPickTemplateSubtitle;

  /// Privacy title
  ///
  /// In en, this message translates to:
  /// **'Your Privacy Matters'**
  String get privacyTitle;

  /// Privacy subtitle
  ///
  /// In en, this message translates to:
  /// **'We believe in transparency. Please review and manage how your data is handled.'**
  String get privacySubtitle;

  /// Health data consent title
  ///
  /// In en, this message translates to:
  /// **'Health Data Processing'**
  String get consentHealthTitle;

  /// Health data consent description
  ///
  /// In en, this message translates to:
  /// **'Required to track medications and symptoms locally.'**
  String get consentHealthDescription;

  /// Fitness data consent title
  ///
  /// In en, this message translates to:
  /// **'Fitness Data Processing'**
  String get consentFitnessTitle;

  /// Fitness data consent description
  ///
  /// In en, this message translates to:
  /// **'Required to log workouts and track progress locally.'**
  String get consentFitnessDescription;

  /// Analytics consent title
  ///
  /// In en, this message translates to:
  /// **'Analytics & Usage'**
  String get consentAnalyticsTitle;

  /// Analytics consent description
  ///
  /// In en, this message translates to:
  /// **'Help us improve VitalSynch by sharing anonymous usage data.'**
  String get consentAnalyticsDescription;

  /// Backup consent title
  ///
  /// In en, this message translates to:
  /// **'Cloud Backup'**
  String get consentBackupTitle;

  /// Backup consent description
  ///
  /// In en, this message translates to:
  /// **'Securely backup your data to the cloud so you don\'t lose it.'**
  String get consentBackupDescription;

  /// Read privacy policy link
  ///
  /// In en, this message translates to:
  /// **'Read Full Privacy Policy'**
  String get readPrivacyPolicy;

  /// Shown when an external link (e.g. privacy policy) fails to open
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the link. Please try again later.'**
  String get linkOpenError;

  /// Privacy policy settings tile title
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Privacy policy settings tile subtitle
  ///
  /// In en, this message translates to:
  /// **'How we collect and use your data'**
  String get privacyPolicySubtitle;

  /// Terms of service settings tile title
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// Terms of service settings tile subtitle
  ///
  /// In en, this message translates to:
  /// **'The terms you agree to by using the app'**
  String get termsOfServiceSubtitle;

  /// Support settings tile title
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// Support settings tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Get help and contact us'**
  String get supportSubtitle;

  /// Accept and continue button
  ///
  /// In en, this message translates to:
  /// **'Accept & Continue'**
  String get acceptContinue;

  /// Required tag
  ///
  /// In en, this message translates to:
  /// **'REQUIRED'**
  String get requiredTag;

  /// Consent required message
  ///
  /// In en, this message translates to:
  /// **'This is required for the {module} module to function.'**
  String consentRequiredMessage(String module);

  /// Welcome back title
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// Sign in subtitle
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue your healthy journey'**
  String get signInSubtitle;

  /// Email label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Password label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Forgot password button
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// Log in button
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get logIn;

  /// OR separator
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orSeparator;

  /// Continue with Apple button
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// Don't have account text
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// Sign up button
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// Enter email error
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get enterEmail;

  /// Invalid email format error
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get invalidEmail;

  /// Enter password error
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get enterPassword;

  /// Login failed error
  ///
  /// In en, this message translates to:
  /// **'Login failed: {error}'**
  String loginFailed(Object error);

  /// Apple login failed error
  ///
  /// In en, this message translates to:
  /// **'Apple Login failed: {error}'**
  String appleLoginFailed(Object error);

  /// Create account title
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// Join VitalSynch subtitle
  ///
  /// In en, this message translates to:
  /// **'Join VitalSynch today'**
  String get joinVitalSynch;

  /// Confirm password label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Already have account text
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// Passwords do not match error
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// Password length error
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordLengthError;

  /// Confirm password error
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get confirmPasswordError;

  /// Registration failed error
  ///
  /// In en, this message translates to:
  /// **'Registration failed: {error}'**
  String registrationFailed(Object error);

  /// Reset password title
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// Reset password subtitle
  ///
  /// In en, this message translates to:
  /// **'Enter your email to receive a reset link'**
  String get resetPasswordSubtitle;

  /// Send reset link button
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// Reset email sent message
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent. Check your inbox.'**
  String get resetEmailSent;

  /// Reset password error
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String resetPasswordError(Object error);

  /// Onboarding welcome title
  ///
  /// In en, this message translates to:
  /// **'Welcome to VitalSynch'**
  String get onboardingWelcomeTitle;

  /// Onboarding welcome subtitle
  ///
  /// In en, this message translates to:
  /// **'Your all-in-one health & fitness companion'**
  String get onboardingWelcomeSubtitle;

  /// Onboarding privacy note
  ///
  /// In en, this message translates to:
  /// **'Your data stays on your device. We respect your privacy.'**
  String get onboardingPrivacyNote;

  /// Onboarding health feature title
  ///
  /// In en, this message translates to:
  /// **'Track Your Health'**
  String get onboardingHealthTitle;

  /// Onboarding health feature description
  ///
  /// In en, this message translates to:
  /// **'Manage medications, symptoms, and health timeline'**
  String get onboardingHealthDescription;

  /// Onboarding health feature 1
  ///
  /// In en, this message translates to:
  /// **'Never miss a medication with smart reminders'**
  String get onboardingHealthFeature1;

  /// Onboarding health feature 2
  ///
  /// In en, this message translates to:
  /// **'Log symptoms and track patterns'**
  String get onboardingHealthFeature2;

  /// Onboarding health feature 3
  ///
  /// In en, this message translates to:
  /// **'View your complete health timeline'**
  String get onboardingHealthFeature3;

  /// Onboarding fitness feature title
  ///
  /// In en, this message translates to:
  /// **'Elevate Your Fitness'**
  String get onboardingFitnessTitle;

  /// Onboarding fitness feature description
  ///
  /// In en, this message translates to:
  /// **'Log workouts, track progress, crush your goals'**
  String get onboardingFitnessDescription;

  /// Onboarding fitness feature 1
  ///
  /// In en, this message translates to:
  /// **'Track workouts with detailed exercise logging'**
  String get onboardingFitnessFeature1;

  /// Onboarding fitness feature 2
  ///
  /// In en, this message translates to:
  /// **'Monitor your progress with visual charts'**
  String get onboardingFitnessFeature2;

  /// Onboarding fitness feature 3
  ///
  /// In en, this message translates to:
  /// **'Unlock achievements and build streaks'**
  String get onboardingFitnessFeature3;

  /// Onboarding privacy screen title
  ///
  /// In en, this message translates to:
  /// **'Your Privacy, Your Control'**
  String get onboardingPrivacyTitle;

  /// Onboarding privacy screen description
  ///
  /// In en, this message translates to:
  /// **'Choose what data you want to share'**
  String get onboardingPrivacyDescription;

  /// Onboarding preferences screen title
  ///
  /// In en, this message translates to:
  /// **'Personalize Your Experience'**
  String get onboardingPreferencesTitle;

  /// Onboarding preferences screen description
  ///
  /// In en, this message translates to:
  /// **'Set your language and theme preferences'**
  String get onboardingPreferencesDescription;

  /// Onboarding preferences note
  ///
  /// In en, this message translates to:
  /// **'You can change these settings anytime'**
  String get onboardingPreferencesNote;

  /// GDPR analytics consent title
  ///
  /// In en, this message translates to:
  /// **'Analytics & Insights'**
  String get gdprAnalyticsTitle;

  /// GDPR analytics consent description
  ///
  /// In en, this message translates to:
  /// **'Help us improve the app with anonymous usage data'**
  String get gdprAnalyticsDescription;

  /// GDPR health data consent title
  ///
  /// In en, this message translates to:
  /// **'Health Data Storage'**
  String get gdprHealthDataTitle;

  /// GDPR health data consent description
  ///
  /// In en, this message translates to:
  /// **'Store your medication and symptom data (required)'**
  String get gdprHealthDataDescription;

  /// GDPR fitness data consent title
  ///
  /// In en, this message translates to:
  /// **'Fitness Data Storage'**
  String get gdprFitnessDataTitle;

  /// GDPR fitness data consent description
  ///
  /// In en, this message translates to:
  /// **'Store your workout and progress data (required)'**
  String get gdprFitnessDataDescription;

  /// GDPR cloud backup consent title
  ///
  /// In en, this message translates to:
  /// **'Cloud Backup'**
  String get gdprCloudBackupTitle;

  /// GDPR cloud backup consent description
  ///
  /// In en, this message translates to:
  /// **'Backup your data to the cloud for sync across devices'**
  String get gdprCloudBackupDescription;

  /// GDPR consent note
  ///
  /// In en, this message translates to:
  /// **'Required consents are necessary for core app functionality. You can manage consents anytime in Settings.'**
  String get gdprNote;

  /// Workout complete message
  ///
  /// In en, this message translates to:
  /// **'Workout Complete!'**
  String get workoutComplete;

  /// Congratulations message
  ///
  /// In en, this message translates to:
  /// **'Great job! Keep it up!'**
  String get greatJob;

  /// Workout not found error message
  ///
  /// In en, this message translates to:
  /// **'Workout not found'**
  String get workoutNotFound;

  /// Done button
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Share button
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Coming soon message
  ///
  /// In en, this message translates to:
  /// **'Coming soon!'**
  String get comingSoon;

  /// Volume chart title
  ///
  /// In en, this message translates to:
  /// **'Volume Chart'**
  String get volumeChart;

  /// Empty state shown when a chart has no data yet
  ///
  /// In en, this message translates to:
  /// **'No workout data yet — log a workout to see your progress'**
  String get chartComingSoon;

  /// Summary section title
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// Average duration label
  ///
  /// In en, this message translates to:
  /// **'Avg Duration'**
  String get avgDuration;

  /// Personal records achieved label
  ///
  /// In en, this message translates to:
  /// **'PRs Achieved'**
  String get prsAchieved;

  /// No PRs empty state message
  ///
  /// In en, this message translates to:
  /// **'No personal records yet. Keep lifting!'**
  String get noPRsYet;

  /// Dismissed tab label
  ///
  /// In en, this message translates to:
  /// **'Dismissed'**
  String get dismissed;

  /// Overall wellness / cross-module filter label
  ///
  /// In en, this message translates to:
  /// **'Overall Wellness'**
  String get overallWellness;

  /// Snackbar message when insight is dismissed
  ///
  /// In en, this message translates to:
  /// **'Insight dismissed'**
  String get insightDismissed;

  /// Empty state for dismissed insights tab
  ///
  /// In en, this message translates to:
  /// **'No dismissed insights'**
  String get noDismissedInsights;

  /// Empty state title when no insights exist
  ///
  /// In en, this message translates to:
  /// **'No insights yet'**
  String get noInsightsYet;

  /// Empty state description for insights
  ///
  /// In en, this message translates to:
  /// **'Insights will appear here as data is collected'**
  String get insightsEmptyDescription;

  /// Progress text showing days of data collected
  ///
  /// In en, this message translates to:
  /// **'{collected}/{total} days of data collected'**
  String dataCollectedProgress(int collected, int total);

  /// Error message when loading insights fails
  ///
  /// In en, this message translates to:
  /// **'Error loading insights: {error}'**
  String errorLoadingInsights(Object error);

  /// Error message when loading dismissed insights fails
  ///
  /// In en, this message translates to:
  /// **'Error loading dismissed insights: {error}'**
  String errorLoadingDismissedInsights(Object error);

  /// No description provided for @symptomHeadache.
  ///
  /// In en, this message translates to:
  /// **'Headache'**
  String get symptomHeadache;

  /// No description provided for @symptomNausea.
  ///
  /// In en, this message translates to:
  /// **'Nausea'**
  String get symptomNausea;

  /// No description provided for @symptomFatigue.
  ///
  /// In en, this message translates to:
  /// **'Fatigue'**
  String get symptomFatigue;

  /// No description provided for @symptomDizziness.
  ///
  /// In en, this message translates to:
  /// **'Dizziness'**
  String get symptomDizziness;

  /// No description provided for @symptomStomachPain.
  ///
  /// In en, this message translates to:
  /// **'Stomach Pain'**
  String get symptomStomachPain;

  /// No description provided for @symptomBackPain.
  ///
  /// In en, this message translates to:
  /// **'Back Pain'**
  String get symptomBackPain;

  /// No description provided for @symptomJointPain.
  ///
  /// In en, this message translates to:
  /// **'Joint Pain'**
  String get symptomJointPain;

  /// No description provided for @symptomInsomnia.
  ///
  /// In en, this message translates to:
  /// **'Insomnia'**
  String get symptomInsomnia;

  /// No description provided for @symptomAnxiety.
  ///
  /// In en, this message translates to:
  /// **'Anxiety'**
  String get symptomAnxiety;

  /// No description provided for @symptomShortnessOfBreath.
  ///
  /// In en, this message translates to:
  /// **'Shortness of Breath'**
  String get symptomShortnessOfBreath;

  /// No description provided for @pleaseEnterSymptomName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a symptom name'**
  String get pleaseEnterSymptomName;

  /// No description provided for @symptomLoggedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Symptom logged successfully'**
  String get symptomLoggedSuccess;

  /// No description provided for @errorLoggingSymptom.
  ///
  /// In en, this message translates to:
  /// **'Error logging symptom: {error}'**
  String errorLoggingSymptom(Object error);

  /// No description provided for @severityMild.
  ///
  /// In en, this message translates to:
  /// **'Mild'**
  String get severityMild;

  /// No description provided for @severityModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get severityModerate;

  /// No description provided for @severitySevere.
  ///
  /// In en, this message translates to:
  /// **'Severe'**
  String get severitySevere;

  /// No description provided for @severityVerySevere.
  ///
  /// In en, this message translates to:
  /// **'Very Severe'**
  String get severityVerySevere;

  /// No description provided for @severityUnbearable.
  ///
  /// In en, this message translates to:
  /// **'Unbearable'**
  String get severityUnbearable;

  /// No description provided for @medicationNotFound.
  ///
  /// In en, this message translates to:
  /// **'Medication not found'**
  String get medicationNotFound;

  /// No description provided for @errorLoadingMedication.
  ///
  /// In en, this message translates to:
  /// **'Error loading medication: {error}'**
  String errorLoadingMedication(Object error);

  /// No description provided for @medicationAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Medication added successfully'**
  String get medicationAddedSuccess;

  /// No description provided for @medicationUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Medication updated successfully'**
  String get medicationUpdatedSuccess;

  /// No description provided for @errorSavingMedication.
  ///
  /// In en, this message translates to:
  /// **'Error saving medication: {error}'**
  String errorSavingMedication(Object error);

  /// No description provided for @addFirstMedicationButton.
  ///
  /// In en, this message translates to:
  /// **'Add First Medication'**
  String get addFirstMedicationButton;

  /// No description provided for @welcomeToHealth.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Health!'**
  String get welcomeToHealth;

  /// No description provided for @onboardingHealthMessage.
  ///
  /// In en, this message translates to:
  /// **'Let\'s get started by adding your first medication. Tracking adherence helps you stay healthy!'**
  String get onboardingHealthMessage;

  /// No description provided for @weeklyReport.
  ///
  /// In en, this message translates to:
  /// **'Weekly Report'**
  String get weeklyReport;

  /// No description provided for @errorLoadingReport.
  ///
  /// In en, this message translates to:
  /// **'Error loading report: {error}'**
  String errorLoadingReport(Object error);

  /// No description provided for @taken.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get taken;

  /// No description provided for @missed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get missed;

  /// No description provided for @skipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get skipped;

  /// No description provided for @volume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volume;

  /// No description provided for @healthRing.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get healthRing;

  /// No description provided for @fitnessRing.
  ///
  /// In en, this message translates to:
  /// **'Fitness'**
  String get fitnessRing;

  /// No description provided for @wellnessRing.
  ///
  /// In en, this message translates to:
  /// **'Wellness'**
  String get wellnessRing;

  /// No description provided for @activityRings.
  ///
  /// In en, this message translates to:
  /// **'Activity Rings'**
  String get activityRings;

  /// No description provided for @shareAsInfographic.
  ///
  /// In en, this message translates to:
  /// **'Share as Infographic (1080x1920)'**
  String get shareAsInfographic;

  /// No description provided for @perfectForStories.
  ///
  /// In en, this message translates to:
  /// **'Perfect for Instagram Stories'**
  String get perfectForStories;

  /// No description provided for @shareAsCompactCard.
  ///
  /// In en, this message translates to:
  /// **'Share as Compact Card (1080x1080)'**
  String get shareAsCompactCard;

  /// No description provided for @perfectForSharing.
  ///
  /// In en, this message translates to:
  /// **'Perfect for general sharing'**
  String get perfectForSharing;

  /// No description provided for @exportAsJSON.
  ///
  /// In en, this message translates to:
  /// **'Export as JSON'**
  String get exportAsJSON;

  /// No description provided for @gdprDataPortability.
  ///
  /// In en, this message translates to:
  /// **'GDPR data portability'**
  String get gdprDataPortability;

  /// No description provided for @generatingImage.
  ///
  /// In en, this message translates to:
  /// **'Generating image...'**
  String get generatingImage;

  /// No description provided for @myWeeklyReport.
  ///
  /// In en, this message translates to:
  /// **'My weekly report from VitalSynch'**
  String get myWeeklyReport;

  /// No description provided for @errorSharing.
  ///
  /// In en, this message translates to:
  /// **'Error sharing: {error}'**
  String errorSharing(Object error);

  /// No description provided for @weeklyReportData.
  ///
  /// In en, this message translates to:
  /// **'VitalSynch Weekly Report Data'**
  String get weeklyReportData;

  /// No description provided for @reportExportedAsJSON.
  ///
  /// In en, this message translates to:
  /// **'Report exported as JSON'**
  String get reportExportedAsJSON;

  /// No description provided for @errorExporting.
  ///
  /// In en, this message translates to:
  /// **'Error exporting: {error}'**
  String errorExporting(Object error);

  /// No description provided for @wasThisInsightHelpful.
  ///
  /// In en, this message translates to:
  /// **'Was this insight helpful?'**
  String get wasThisInsightHelpful;

  /// No description provided for @helpful.
  ///
  /// In en, this message translates to:
  /// **'Helpful'**
  String get helpful;

  /// No description provided for @notHelpful.
  ///
  /// In en, this message translates to:
  /// **'Not Helpful'**
  String get notHelpful;

  /// No description provided for @dismissInsight.
  ///
  /// In en, this message translates to:
  /// **'Dismiss Insight'**
  String get dismissInsight;

  /// No description provided for @thankYouForFeedback.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your feedback!'**
  String get thankYouForFeedback;

  /// No description provided for @errorSubmittingFeedback.
  ///
  /// In en, this message translates to:
  /// **'Error submitting feedback: {error}'**
  String errorSubmittingFeedback(Object error);

  /// No description provided for @errorDismissingInsight.
  ///
  /// In en, this message translates to:
  /// **'Error dismissing insight: {error}'**
  String errorDismissingInsight(Object error);

  /// No description provided for @privacyAndData.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Data'**
  String get privacyAndData;

  /// No description provided for @restTimerSeconds.
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get restTimerSeconds;

  /// No description provided for @skipRestButton.
  ///
  /// In en, this message translates to:
  /// **'Skip Rest'**
  String get skipRestButton;

  /// No description provided for @achievementUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Achievement Unlocked!'**
  String get achievementUnlocked;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorGeneric(Object error);

  /// No description provided for @healthSummary.
  ///
  /// In en, this message translates to:
  /// **'Health Summary'**
  String get healthSummary;

  /// No description provided for @fitnessSummary.
  ///
  /// In en, this message translates to:
  /// **'Fitness Summary'**
  String get fitnessSummary;

  /// No description provided for @nextWeekSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Next Week Suggestions'**
  String get nextWeekSuggestions;

  /// No description provided for @keepUpGreatWork.
  ///
  /// In en, this message translates to:
  /// **'Keep up the great work!'**
  String get keepUpGreatWork;

  /// No description provided for @vsLastWeekPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% vs last week'**
  String vsLastWeekPercent(String percent);

  /// No description provided for @mostMissed.
  ///
  /// In en, this message translates to:
  /// **'Most missed: {timeSlot}'**
  String mostMissed(String timeSlot);

  /// No description provided for @bestWorkout.
  ///
  /// In en, this message translates to:
  /// **'Best workout: {name} — {volume}kg'**
  String bestWorkout(String name, String volume);

  /// Weekly report: the weekday the service picked as the best of the week
  ///
  /// In en, this message translates to:
  /// **'Best day: {day}'**
  String bestDay(String day);

  /// No description provided for @newPersonalRecords.
  ///
  /// In en, this message translates to:
  /// **'New Personal Records'**
  String get newPersonalRecords;

  /// No description provided for @validUntilDays.
  ///
  /// In en, this message translates to:
  /// **'Valid until {days} days'**
  String validUntilDays(int days);

  /// No description provided for @validUntilHours.
  ///
  /// In en, this message translates to:
  /// **'Valid until {hours} hours'**
  String validUntilHours(int hours);

  /// No description provided for @validUntilSoon.
  ///
  /// In en, this message translates to:
  /// **'Valid until soon'**
  String get validUntilSoon;

  /// No description provided for @takeAction.
  ///
  /// In en, this message translates to:
  /// **'Take Action'**
  String get takeAction;

  /// No description provided for @errorLoadingInsight.
  ///
  /// In en, this message translates to:
  /// **'Error loading insight: {error}'**
  String errorLoadingInsight(Object error);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String daysAgo(int days);

  /// No description provided for @weeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{weeks}w ago'**
  String weeksAgo(int weeks);

  /// No description provided for @monthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{months}mo ago'**
  String monthsAgo(int months);

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @errorAddingSet.
  ///
  /// In en, this message translates to:
  /// **'Error adding set: {error}'**
  String errorAddingSet(Object error);

  /// No description provided for @chartError.
  ///
  /// In en, this message translates to:
  /// **'Chart Error'**
  String get chartError;

  /// No description provided for @shareFunctionalityComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Share functionality coming soon!'**
  String get shareFunctionalityComingSoon;

  /// No description provided for @severityLabel.
  ///
  /// In en, this message translates to:
  /// **'Severity: {severity}'**
  String severityLabel(int severity);

  /// No description provided for @errorLoadingCalendar.
  ///
  /// In en, this message translates to:
  /// **'Error loading calendar'**
  String get errorLoadingCalendar;

  /// Create template button label
  ///
  /// In en, this message translates to:
  /// **'Create Template'**
  String get createTemplate;

  /// Create first template guidance
  ///
  /// In en, this message translates to:
  /// **'Create your first template to quickly start workouts'**
  String get createFirstTemplate;

  /// Template saved confirmation
  ///
  /// In en, this message translates to:
  /// **'Template saved'**
  String get templateSaved;

  /// Select exercises guidance
  ///
  /// In en, this message translates to:
  /// **'Select exercises for your template'**
  String get selectExercises;

  /// Default values section header
  ///
  /// In en, this message translates to:
  /// **'Default Values'**
  String get defaultValues;

  /// Share as Instagram story format
  ///
  /// In en, this message translates to:
  /// **'Story Format'**
  String get shareAsStory;

  /// Share as compact card format
  ///
  /// In en, this message translates to:
  /// **'Compact Card'**
  String get shareAsCompact;

  /// Export as JSON format
  ///
  /// In en, this message translates to:
  /// **'Export JSON'**
  String get exportAsJson;

  /// Branded watermark text
  ///
  /// In en, this message translates to:
  /// **'Tracked with VitalSync'**
  String get trackedWithVitalSync;

  /// Biometric login setting
  ///
  /// In en, this message translates to:
  /// **'Biometric Login'**
  String get biometricLogin;

  /// Biometric login description
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint or face recognition to sign in quickly'**
  String get biometricLoginDescription;

  /// Shown when biometric unlock finds no valid saved session
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get biometricSessionExpired;

  /// Dashboard edit mode title
  ///
  /// In en, this message translates to:
  /// **'Edit Dashboard'**
  String get dashboardEditMode;

  /// Reorder hint text
  ///
  /// In en, this message translates to:
  /// **'Long press and drag to reorder cards'**
  String get longPressToReorder;

  /// Previous week legend label
  ///
  /// In en, this message translates to:
  /// **'Prev. Week'**
  String get previousWeek;

  /// Security settings section title
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// Weight/reps parse error
  ///
  /// In en, this message translates to:
  /// **'Please enter valid weight and reps'**
  String get enterValidWeightAndReps;

  /// Weight bounds validation
  ///
  /// In en, this message translates to:
  /// **'Weight must be between 0 and 999 kg'**
  String get weightOutOfRange;

  /// Reps bounds validation
  ///
  /// In en, this message translates to:
  /// **'Reps must be between 1 and 999'**
  String get repsOutOfRange;

  /// Title of the follow-up notification asking the user to log a dose
  ///
  /// In en, this message translates to:
  /// **'Did you take your medication?'**
  String get medicationFollowUpTitle;

  /// Body of the follow-up notification asking the user to log a dose
  ///
  /// In en, this message translates to:
  /// **'Did you take {name}? Don\'t forget to log it.'**
  String medicationFollowUpBody(String name);

  /// Sign-up email confirmation screen title
  ///
  /// In en, this message translates to:
  /// **'Verify Your Email'**
  String get verifyEmailTitle;

  /// Sign-up email confirmation screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Enter the verification code we sent to {email}'**
  String verifyEmailSubtitle(String email);

  /// Confirmation code field hint
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get verificationCode;

  /// Empty confirmation code validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter the verification code'**
  String get enterVerificationCode;

  /// Confirmation code length validation error
  ///
  /// In en, this message translates to:
  /// **'The code must be 6 digits'**
  String get verificationCodeTooShort;

  /// Confirm sign-up submit button
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyButton;

  /// Resend confirmation code button
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// Confirmation code resent snackbar
  ///
  /// In en, this message translates to:
  /// **'A new verification code was sent to your email.'**
  String get codeResent;

  /// Confirmation code resend failure snackbar
  ///
  /// In en, this message translates to:
  /// **'Could not resend the code: {error}'**
  String resendCodeFailed(Object error);

  /// Sign-up confirmation failure snackbar
  ///
  /// In en, this message translates to:
  /// **'Verification failed: {error}'**
  String verificationFailed(Object error);

  /// Snackbar after successful email confirmation when auto sign-in is unavailable
  ///
  /// In en, this message translates to:
  /// **'Email verified. Please log in.'**
  String get emailVerifiedPleaseLogin;

  /// Glucose section label
  ///
  /// In en, this message translates to:
  /// **'Glucose'**
  String get glucose;

  /// Glucose list screen title
  ///
  /// In en, this message translates to:
  /// **'Glucose Readings'**
  String get glucoseReadings;

  /// Add glucose reading button label
  ///
  /// In en, this message translates to:
  /// **'Log Reading'**
  String get logGlucoseReading;

  /// Glucose list empty state
  ///
  /// In en, this message translates to:
  /// **'No readings logged yet'**
  String get noGlucoseReadings;

  /// Glucose value input label
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get glucoseValue;

  /// Glucose unit selector label
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get glucoseUnit;

  /// Milligrams per decilitre unit suffix
  ///
  /// In en, this message translates to:
  /// **'mg/dL'**
  String get glucoseUnitMgDl;

  /// Millimoles per litre unit suffix
  ///
  /// In en, this message translates to:
  /// **'mmol/L'**
  String get glucoseUnitMmolL;

  /// Glucose measurement time label
  ///
  /// In en, this message translates to:
  /// **'Measured at'**
  String get glucoseMeasuredAt;

  /// Meal context selector label
  ///
  /// In en, this message translates to:
  /// **'Context'**
  String get glucoseContext;

  /// Meal context: fasting
  ///
  /// In en, this message translates to:
  /// **'Fasting'**
  String get glucoseContextFasting;

  /// Meal context: before a meal
  ///
  /// In en, this message translates to:
  /// **'Before meal'**
  String get glucoseContextPreMeal;

  /// Meal context: after a meal
  ///
  /// In en, this message translates to:
  /// **'After meal'**
  String get glucoseContextPostMeal;

  /// Meal context: other
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get glucoseContextOther;

  /// No meal context recorded
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get glucoseContextNone;

  /// Reading was typed in by the user
  ///
  /// In en, this message translates to:
  /// **'Entered manually'**
  String get glucoseSourceManual;

  /// Reading was imported from Apple Health
  ///
  /// In en, this message translates to:
  /// **'From Apple Health'**
  String get glucoseSourceAppleHealth;

  /// Validation: glucose value is empty
  ///
  /// In en, this message translates to:
  /// **'Enter a value'**
  String get pleaseEnterGlucoseValue;

  /// Validation: glucose value is not a number
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get invalidGlucoseValue;

  /// Snackbar after saving a glucose reading
  ///
  /// In en, this message translates to:
  /// **'Reading saved'**
  String get glucoseLoggedSuccess;

  /// Snackbar when saving a glucose reading fails
  ///
  /// In en, this message translates to:
  /// **'Could not save the reading: {error}'**
  String errorLoggingGlucose(Object error);

  /// Glucose timeline screen title
  ///
  /// In en, this message translates to:
  /// **'Last 24 Hours'**
  String get glucoseToday;

  /// Glucose timeline empty state
  ///
  /// In en, this message translates to:
  /// **'No readings in the last 24 hours'**
  String get noGlucoseInWindow;

  /// Count of glucose readings
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{reading} other{readings}}'**
  String glucoseReadingCount(int count);

  /// Glucose timeline chart legend: the measurement line
  ///
  /// In en, this message translates to:
  /// **'Readings'**
  String get chartLegendReadings;

  /// Glucose timeline chart legend: the meal markers
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get chartLegendMeals;

  /// Meal list screen title
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get meals;

  /// Add meal button label
  ///
  /// In en, this message translates to:
  /// **'Log Meal'**
  String get logMeal;

  /// Meal list empty state
  ///
  /// In en, this message translates to:
  /// **'No meals logged yet'**
  String get noMealsLogged;

  /// Meal name input label
  ///
  /// In en, this message translates to:
  /// **'Meal'**
  String get mealName;

  /// Meal time label
  ///
  /// In en, this message translates to:
  /// **'Eaten at'**
  String get mealEatenAt;

  /// Meal tag selector label
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get mealTags;

  /// Validation: meal name is empty
  ///
  /// In en, this message translates to:
  /// **'Enter a meal name'**
  String get pleaseEnterMealName;

  /// Snackbar after saving a meal
  ///
  /// In en, this message translates to:
  /// **'Meal saved'**
  String get mealLoggedSuccess;

  /// Snackbar when saving a meal fails
  ///
  /// In en, this message translates to:
  /// **'Could not save the meal: {error}'**
  String errorLoggingMeal(Object error);

  /// Count of logged meals
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{meal} other{meals}}'**
  String mealCount(int count);

  /// Meal tag suggestion
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get mealTagBreakfast;

  /// Meal tag suggestion
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get mealTagLunch;

  /// Meal tag suggestion
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get mealTagDinner;

  /// Meal tag suggestion
  ///
  /// In en, this message translates to:
  /// **'Snack'**
  String get mealTagSnack;

  /// Meal tag suggestion
  ///
  /// In en, this message translates to:
  /// **'Drink'**
  String get mealTagDrink;

  /// Meal tag suggestion
  ///
  /// In en, this message translates to:
  /// **'Eating out'**
  String get mealTagEatingOut;

  /// Health sources settings screen title
  ///
  /// In en, this message translates to:
  /// **'Health Sources'**
  String get healthSources;

  /// Health sources settings tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Apple Health connection and imports'**
  String get healthSourcesSubtitle;

  /// Name of the Apple Health data source
  ///
  /// In en, this message translates to:
  /// **'Apple Health'**
  String get appleHealth;

  /// Apple Health read access is granted
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get healthSourceConnected;

  /// Apple Health read access is not granted
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get healthSourceNotConnected;

  /// Request Apple Health read access
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get healthSourceConnect;

  /// Release Apple Health read access
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get healthSourceDisconnect;

  /// Run an Apple Health import immediately
  ///
  /// In en, this message translates to:
  /// **'Import now'**
  String get healthSourceImportNow;

  /// Timestamp of the last successful import
  ///
  /// In en, this message translates to:
  /// **'Last import'**
  String get healthSourceLastImport;

  /// No import has run yet
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get healthSourceNeverImported;

  /// Read-only guarantee shown on the health sources screen
  ///
  /// In en, this message translates to:
  /// **'VitalSync only reads from Apple Health. It never writes to it.'**
  String get healthSourceReadOnlyNotice;

  /// Result of an Apple Health import
  ///
  /// In en, this message translates to:
  /// **'{count} new {count, plural, =1{record} other{records}} imported'**
  String healthSourceImported(int count);

  /// Import completed but found nothing new
  ///
  /// In en, this message translates to:
  /// **'No new records'**
  String get healthSourceNothingNew;

  /// Snackbar when an Apple Health import fails
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String healthSourceImportFailed(Object error);

  /// Snackbar after disconnecting
  ///
  /// In en, this message translates to:
  /// **'Disconnected from Apple Health'**
  String get healthSourceDisconnected;

  /// Header for the list of sample types read
  ///
  /// In en, this message translates to:
  /// **'Data read'**
  String get healthSourceTypesTitle;

  /// Apple Health sample type read by VitalSync
  ///
  /// In en, this message translates to:
  /// **'Blood glucose'**
  String get healthSourceTypeGlucose;

  /// Apple Health sample type read by VitalSync
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get healthSourceTypeSteps;

  /// Apple Health sample type read by VitalSync
  ///
  /// In en, this message translates to:
  /// **'Active energy'**
  String get healthSourceTypeActiveEnergy;

  /// Apple Health sample type read by VitalSync
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get healthSourceTypeWorkouts;

  /// Apple Health sample type read by VitalSync
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get healthSourceTypeSleep;

  /// Badge on a meal that has enough readings around it
  ///
  /// In en, this message translates to:
  /// **'Measurement data'**
  String get mealCoverageCovered;

  /// Badge on a meal that does not have enough readings around it
  ///
  /// In en, this message translates to:
  /// **'No measurement data'**
  String get mealCoverageUncovered;

  /// Coverage reason: not enough readings in the window
  ///
  /// In en, this message translates to:
  /// **'Too few readings'**
  String get mealCoverageReasonNoReadings;

  /// Coverage reason: readings leave too wide a gap
  ///
  /// In en, this message translates to:
  /// **'Gap between readings'**
  String get mealCoverageReasonGapInData;

  /// Coverage reason: a second meal shares the window
  ///
  /// In en, this message translates to:
  /// **'Another meal nearby'**
  String get mealCoverageReasonOverlappingMeal;

  /// Coverage reason: activity was recorded in the window
  ///
  /// In en, this message translates to:
  /// **'Activity recorded'**
  String get mealCoverageReasonActivityInWindow;

  /// Weekly report line stating how many meals had readings around them
  ///
  /// In en, this message translates to:
  /// **'{covered} of {total} meals had measurement data'**
  String weeklyMealCoverage(int covered, int total);

  /// Settings toggle for the opt-in counters
  ///
  /// In en, this message translates to:
  /// **'Calibration Metrics'**
  String get calibrationMetrics;

  /// Settings toggle subtitle
  ///
  /// In en, this message translates to:
  /// **'Send counts only, never your health data'**
  String get calibrationMetricsSubtitle;

  /// Consent explanation. Must not describe the data as anonymous: it is stored under the user's own account.
  ///
  /// In en, this message translates to:
  /// **'To improve the app, VitalSync sends only the counts — how many meals, how many readings — stored under your account. Meal names, notes and measurement values are not sent. You can turn this off at any time.'**
  String get calibrationMetricsConsentBody;

  /// Snackbar after enabling the opt-in counters
  ///
  /// In en, this message translates to:
  /// **'Calibration metrics turned on'**
  String get calibrationMetricsEnabled;

  /// Snackbar after disabling the opt-in counters
  ///
  /// In en, this message translates to:
  /// **'Calibration metrics turned off'**
  String get calibrationMetricsDisabled;

  /// Title of the post-meal reminder notification. Asks for a measurement only — it must not describe, predict or interpret a reading.
  ///
  /// In en, this message translates to:
  /// **'Time for a measurement'**
  String get postMealReminderTitle;

  /// Body of the post-meal reminder notification. States the elapsed time and asks for an entry. No health comment, advice or prediction.
  ///
  /// In en, this message translates to:
  /// **'It\'s been 2 hours since your meal — would you like to add a reading?'**
  String get postMealReminderBody;

  /// Settings switch title for the post-meal measurement reminder
  ///
  /// In en, this message translates to:
  /// **'Post-meal reminder'**
  String get postMealReminderSetting;

  /// Settings switch subtitle. Describes the fixed time trigger, nothing about readings.
  ///
  /// In en, this message translates to:
  /// **'Ask for a reading 2 hours after a logged meal'**
  String get postMealReminderSettingSubtitle;

  /// Confirmation dialog title for deleting a single glucose reading
  ///
  /// In en, this message translates to:
  /// **'Delete this reading?'**
  String get deleteGlucoseReadingTitle;

  /// Confirmation dialog body. States what is removed; makes no claim about the value itself.
  ///
  /// In en, this message translates to:
  /// **'The measurement is removed from VitalSync. A reading that came from Apple Health stays in Apple Health — VitalSync never writes there.'**
  String get deleteGlucoseReadingMessage;

  /// Snackbar after a reading is deleted
  ///
  /// In en, this message translates to:
  /// **'Reading deleted'**
  String get glucoseReadingDeleted;

  /// Confirmation dialog title for deleting a logged meal
  ///
  /// In en, this message translates to:
  /// **'Delete this meal?'**
  String get deleteMealTitle;

  /// Confirmation dialog body for deleting a logged meal
  ///
  /// In en, this message translates to:
  /// **'The meal and its measurement reminder are removed from VitalSync.'**
  String get deleteMealMessage;

  /// Snackbar after a meal is deleted
  ///
  /// In en, this message translates to:
  /// **'Meal deleted'**
  String get mealDeleted;

  /// Notification title shown when an achievement is unlocked
  ///
  /// In en, this message translates to:
  /// **'Achievement Unlocked!'**
  String get achievementUnlockedTitle;

  /// Achievement name (fitness_first_step)
  ///
  /// In en, this message translates to:
  /// **'First Step'**
  String get achievementFitnessFirstStepTitle;

  /// How to unlock the fitness_first_step achievement
  ///
  /// In en, this message translates to:
  /// **'Complete your first workout'**
  String get achievementFitnessFirstStepDesc;

  /// Achievement name (fitness_week_warrior)
  ///
  /// In en, this message translates to:
  /// **'Week Warrior'**
  String get achievementFitnessWeekWarriorTitle;

  /// How to unlock the fitness_week_warrior achievement
  ///
  /// In en, this message translates to:
  /// **'Maintain a 7-day workout streak'**
  String get achievementFitnessWeekWarriorDesc;

  /// Achievement name (fitness_monthly_master)
  ///
  /// In en, this message translates to:
  /// **'Monthly Master'**
  String get achievementFitnessMonthlyMasterTitle;

  /// How to unlock the fitness_monthly_master achievement
  ///
  /// In en, this message translates to:
  /// **'Maintain a 30-day workout streak'**
  String get achievementFitnessMonthlyMasterDesc;

  /// Achievement name (fitness_iron_will)
  ///
  /// In en, this message translates to:
  /// **'Iron Will'**
  String get achievementFitnessIronWillTitle;

  /// How to unlock the fitness_iron_will achievement
  ///
  /// In en, this message translates to:
  /// **'Maintain a 100-day workout streak'**
  String get achievementFitnessIronWillDesc;

  /// Achievement name (fitness_ton_club)
  ///
  /// In en, this message translates to:
  /// **'Ton Club'**
  String get achievementFitnessTonClubTitle;

  /// How to unlock the fitness_ton_club achievement
  ///
  /// In en, this message translates to:
  /// **'Lift a total of 1,000 kg'**
  String get achievementFitnessTonClubDesc;

  /// Achievement name (fitness_heavy_lifter)
  ///
  /// In en, this message translates to:
  /// **'Heavy Lifter'**
  String get achievementFitnessHeavyLifterTitle;

  /// How to unlock the fitness_heavy_lifter achievement
  ///
  /// In en, this message translates to:
  /// **'Lift a total of 10,000 kg'**
  String get achievementFitnessHeavyLifterDesc;

  /// Achievement name (fitness_powerhouse)
  ///
  /// In en, this message translates to:
  /// **'Powerhouse'**
  String get achievementFitnessPowerhouseTitle;

  /// How to unlock the fitness_powerhouse achievement
  ///
  /// In en, this message translates to:
  /// **'Lift a total of 100,000 kg'**
  String get achievementFitnessPowerhouseDesc;

  /// Achievement name (fitness_mountain_mover)
  ///
  /// In en, this message translates to:
  /// **'Mountain Mover'**
  String get achievementFitnessMountainMoverTitle;

  /// How to unlock the fitness_mountain_mover achievement
  ///
  /// In en, this message translates to:
  /// **'Lift a total of 500,000 kg'**
  String get achievementFitnessMountainMoverDesc;

  /// Achievement name (fitness_beginner)
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get achievementFitnessBeginnerTitle;

  /// How to unlock the fitness_beginner achievement
  ///
  /// In en, this message translates to:
  /// **'Complete 1 workout'**
  String get achievementFitnessBeginnerDesc;

  /// Achievement name (fitness_consistent)
  ///
  /// In en, this message translates to:
  /// **'Consistent'**
  String get achievementFitnessConsistentTitle;

  /// How to unlock the fitness_consistent achievement
  ///
  /// In en, this message translates to:
  /// **'Complete 10 workouts'**
  String get achievementFitnessConsistentDesc;

  /// Achievement name (fitness_dedicated)
  ///
  /// In en, this message translates to:
  /// **'Dedicated'**
  String get achievementFitnessDedicatedTitle;

  /// How to unlock the fitness_dedicated achievement
  ///
  /// In en, this message translates to:
  /// **'Complete 50 workouts'**
  String get achievementFitnessDedicatedDesc;

  /// Achievement name (fitness_gym_rat)
  ///
  /// In en, this message translates to:
  /// **'Gym Rat'**
  String get achievementFitnessGymRatTitle;

  /// How to unlock the fitness_gym_rat achievement
  ///
  /// In en, this message translates to:
  /// **'Complete 100 workouts'**
  String get achievementFitnessGymRatDesc;

  /// Achievement name (fitness_legend)
  ///
  /// In en, this message translates to:
  /// **'Fitness Legend'**
  String get achievementFitnessLegendTitle;

  /// How to unlock the fitness_legend achievement
  ///
  /// In en, this message translates to:
  /// **'Complete 500 workouts'**
  String get achievementFitnessLegendDesc;

  /// Achievement name (fitness_first_pr)
  ///
  /// In en, this message translates to:
  /// **'First PR'**
  String get achievementFitnessFirstPrTitle;

  /// How to unlock the fitness_first_pr achievement
  ///
  /// In en, this message translates to:
  /// **'Set your first personal record'**
  String get achievementFitnessFirstPrDesc;

  /// Achievement name (fitness_record_breaker)
  ///
  /// In en, this message translates to:
  /// **'Record Breaker'**
  String get achievementFitnessRecordBreakerTitle;

  /// How to unlock the fitness_record_breaker achievement
  ///
  /// In en, this message translates to:
  /// **'Set 10 personal records'**
  String get achievementFitnessRecordBreakerDesc;

  /// Achievement name (fitness_elite)
  ///
  /// In en, this message translates to:
  /// **'Elite'**
  String get achievementFitnessEliteTitle;

  /// How to unlock the fitness_elite achievement
  ///
  /// In en, this message translates to:
  /// **'Set 50 personal records'**
  String get achievementFitnessEliteDesc;

  /// Achievement name (health_perfect_day)
  ///
  /// In en, this message translates to:
  /// **'Perfect Day'**
  String get achievementHealthPerfectDayTitle;

  /// How to unlock the health_perfect_day achievement
  ///
  /// In en, this message translates to:
  /// **'Take all medications on schedule for 1 day'**
  String get achievementHealthPerfectDayDesc;

  /// Achievement name (health_week_wellness)
  ///
  /// In en, this message translates to:
  /// **'Week of Wellness'**
  String get achievementHealthWeekWellnessTitle;

  /// How to unlock the health_week_wellness achievement
  ///
  /// In en, this message translates to:
  /// **'Maintain 100% medication compliance for 7 days'**
  String get achievementHealthWeekWellnessDesc;

  /// Achievement name (health_hero)
  ///
  /// In en, this message translates to:
  /// **'Health Hero'**
  String get achievementHealthHeroTitle;

  /// How to unlock the health_hero achievement
  ///
  /// In en, this message translates to:
  /// **'Maintain 100% medication compliance for 30 days'**
  String get achievementHealthHeroDesc;

  /// Achievement name (cross_balance_master)
  ///
  /// In en, this message translates to:
  /// **'Balance Master'**
  String get achievementCrossBalanceMasterTitle;

  /// How to unlock the cross_balance_master achievement
  ///
  /// In en, this message translates to:
  /// **'Keep 90%+ medication compliance this week and a 1-day workout streak'**
  String get achievementCrossBalanceMasterDesc;

  /// Achievement name (cross_synced_up)
  ///
  /// In en, this message translates to:
  /// **'Synced Up'**
  String get achievementCrossSyncedUpTitle;

  /// How to unlock the cross_synced_up achievement
  ///
  /// In en, this message translates to:
  /// **'Keep 90%+ medication compliance this week and a 30-day workout streak'**
  String get achievementCrossSyncedUpDesc;

  /// Achievement name (cross_wellness_warrior)
  ///
  /// In en, this message translates to:
  /// **'Wellness Warrior'**
  String get achievementCrossWellnessWarriorTitle;

  /// How to unlock the cross_wellness_warrior achievement
  ///
  /// In en, this message translates to:
  /// **'Keep 90%+ medication compliance this week and a 50-day workout streak'**
  String get achievementCrossWellnessWarriorDesc;
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
