/// VitalSync — Notification Service.
///
/// Comprehensive local notification system using flutter_local_notifications.
/// Handles medication reminders with actions, fitness notifications,
/// insight alerts, daily summaries, and deep link routing.
///
/// Platform specifics:
/// - Android 13+ POST_NOTIFICATIONS permission
/// - iOS provisional notifications
/// - SCHEDULE_EXACT_ALARM permission
/// - Timezone-aware scheduling
/// - Deep link routing from notification taps
/// - Analytics event tracking on notification interaction
library;

import 'dart:io' show Platform;
import 'dart:ui' show Locale;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:logger/logger.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/fitness/achievement.dart';
import '../../domain/entities/health/medication.dart';
import '../../domain/entities/insights/insight.dart';
import '../analytics/analytics_service.dart';
import '../constants/app_constants.dart';
import '../enums/insight_priority.dart';
import '../enums/medication_frequency.dart';
import '../l10n/achievement_labels.dart';
import '../l10n/app_localizations.dart';

// Notification Action Identifiers

/// Action ID when user taps "Taken" on a medication notification.
const String kActionMedicationTaken = 'medication_taken';

/// Action ID when user taps "Snooze 15 min" on a medication notification.
const String kActionMedicationSnooze = 'medication_snooze';

/// Android notification action category for medication reminders.
const String kCategoryMedication = 'medication_category';

/// Offset added to a medication reminder notification ID to derive the ID
/// of its paired follow-up ("did you log it?") notification.
const int kMedicationFollowUpIdOffset = 100000;

/// Base of the ID range used by post-meal measurement reminders.
const int kPostMealReminderIdOffset = 150000;

/// Base of the ID range used by achievement unlock notifications.
///
/// The achievement's row id is added to it, matching what AchievementService
/// used inline before this moved into the service.
const int kAchievementNotificationIdOffset = 72000;

/// Payload type of the post-meal measurement reminder.
///
/// Full payload shape: `glucose_reminder:<millisecondsSinceEpoch>`, where the
/// timestamp is the moment the reminder fires — i.e. the meal time plus
/// [AppConstants.postMealReminderDelayHours]. It is carried so the entry form
/// can open pre-filled with that time; no meal or reading data travels in it.
const String kPayloadTypeGlucoseReminder = 'glucose_reminder';

/// Payload type of a medication reminder or its follow-up.
/// Full shape: `medication:<medicationId>`.
const String kPayloadTypeMedication = 'medication';

/// Payload type of the evening daily summary. Carries no id.
const String kPayloadTypeDailySummary = 'daily_summary';

/// Payload type of the streak-at-risk warning.
/// Full shape: `streak:<currentStreak>`; the count is informational only.
const String kPayloadTypeStreak = 'streak';

/// Payload type of the Monday weekly-report notification. Carries no id.
const String kPayloadTypeWeeklyReport = 'weekly_report';

/// Payload type of an achievement unlock.
/// Full shape: `achievement:<achievementId>`.
const String kPayloadTypeAchievement = 'achievement';

/// Payload type of a workout reminder. Full shape: `workout:<templateName>`.
///
/// [NotificationService.showWorkoutReminder] currently has no caller; the type
/// is routed anyway so the notification is not dead on arrival if one appears.
const String kPayloadTypeWorkout = 'workout';

/// Payload type of a personal-record celebration.
/// Full shape: `pr:<exerciseName>`. Also has no caller yet — see
/// [kPayloadTypeWorkout].
const String kPayloadTypePersonalRecord = 'pr';

/// Payload type of a high/critical insight alert.
/// Full shape: `insight:<insightId>`.
///
/// Has no caller *and* no destination: `InsightDetailScreen` is not wired to a
/// route. Declared so the type is named in one place when that changes.
const String kPayloadTypeInsight = 'insight';

/// Every payload type this service can emit.
///
/// Exported so `notification_routes_test.dart` can assert that each one has an
/// explicit answer — a destination, or a place in
/// `kUnroutedNotificationPayloadTypes`. A type nobody handled is a notification
/// that opens nothing, and nothing about that failure is visible in a build.
/// **Add new types here as well as above.**
const List<String> kNotificationPayloadTypes = [
  kPayloadTypeGlucoseReminder,
  kPayloadTypeMedication,
  kPayloadTypeDailySummary,
  kPayloadTypeStreak,
  kPayloadTypeWeeklyReport,
  kPayloadTypeAchievement,
  kPayloadTypeWorkout,
  kPayloadTypePersonalRecord,
  kPayloadTypeInsight,
];

// ─────────────────────────────────────────────────────────────────────────────
// Callback typedefs
// ─────────────────────────────────────────────────────────────────────────────

/// Called when a notification is tapped to navigate to the appropriate screen.
/// [type] is the notification type (e.g. 'medication', 'workout', 'insight').
/// [id] is the entity id extracted from the payload.
typedef NotificationNavigationCallback = void Function(String type, String id);

/// Called when a notification action button is tapped (e.g. "Taken", "Snooze").
/// [actionId] is the action identifier.
/// [payload] is the full notification payload string.
typedef NotificationActionCallback =
    void Function(String actionId, String? payload);

// ═════════════════════════════════════════════════════════════════════════════
// NotificationService
// ═════════════════════════════════════════════════════════════════════════════

/// Notification Service for VitalSync.
///
/// Manages local notifications for medication reminders (with actions),
/// workout reminders, streak warnings, PR celebrations, insight alerts,
/// weekly report ready notifications, and daily summaries.
///
/// Deep link routing is handled via payload parsing in [_onNotificationTapped].
class NotificationService {
  NotificationService({
    required FlutterLocalNotificationsPlugin notifications,
    required AnalyticsService analyticsService,
    AppLocalizations Function()? resolveLocalizations,
    Logger? logger,
  }) : _notifications = notifications,
       _analyticsService = analyticsService,
       _resolveLocalizations = resolveLocalizations,
       _logger = logger ?? Logger();

  final FlutterLocalNotificationsPlugin _notifications;
  final AnalyticsService _analyticsService;

  /// Resolves the localizations for notification content scheduled outside
  /// of a widget context (e.g. follow-up reminders). Falls back to English.
  final AppLocalizations Function()? _resolveLocalizations;
  final Logger _logger;

  /// Set this callback to handle navigation when a notification is tapped.
  /// Should be wired up after DI initialization (e.g. in main.dart).
  NotificationNavigationCallback? onNavigationCallback;

  /// Set this callback to handle notification action button taps
  /// (e.g. "Taken", "Snooze 15 min").
  NotificationActionCallback? onActionCallback;

  // INITIALIZATION

  /// Initializes the notification service.
  ///
  /// Sets up notification channels for Android, configures iOS settings,
  /// and registers notification tap/action handlers.
  /// Must be called before using any notification features.
  Future<void> initialize() async {
    // Timezone setup — must run before any tz.local use (reminder scheduling).
    // initializeTimeZones() loads the IANA database (tz.local would otherwise
    // throw LateInitializationError); then we point tz.local at the device's
    // zone so reminders fire at the correct LOCAL wall-clock time. If device
    // detection fails we fall back to UTC so init never breaks.
    tz_data.initializeTimeZones();
    try {
      final localZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localZone.identifier));
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('UTC'));
      _logger.w('Local timezone detection failed; falling back to UTC: $e');
    }

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS initialization settings — request provisional on first launch
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // We'll request explicitly
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          kCategoryMedication,
          actions: [
            DarwinNotificationAction.plain(
              kActionMedicationTaken,
              'Taken ✓',
              options: {DarwinNotificationActionOption.foreground},
            ),
            DarwinNotificationAction.plain(
              kActionMedicationSnooze,
              'Snooze 15 min',
            ),
          ],
        ),
      ],
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    await _createNotificationChannels();

    _logger.i('NotificationService initialized');
  }

  // PERMISSIONS

  /// Requests notification permissions from the user.
  ///
  /// Handles platform-specific permission flows:
  /// - **Android 13+**: Requests POST_NOTIFICATIONS runtime permission.
  /// - **Android**: Requests SCHEDULE_EXACT_ALARM for precise medication timing.
  /// - **iOS**: Requests alert, badge, and sound permissions.
  ///
  /// Returns `true` if permissions are granted, `false` otherwise.
  Future<bool> requestPermissions() async {
    var granted = true;

    if (Platform.isAndroid) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        // Android 13+ POST_NOTIFICATIONS permission
        final notifPermission = await androidPlugin
            .requestNotificationsPermission();
        granted = notifPermission ?? true;

        // SCHEDULE_EXACT_ALARM permission for precise medication reminders
        final exactAlarmPermission = await androidPlugin
            .requestExactAlarmsPermission();
        if (exactAlarmPermission != true) {
          _logger.w(
            'Exact alarm permission not granted — '
            'medication reminders may be imprecise',
          );
        }
      }
    } else if (Platform.isIOS) {
      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();

      if (iosPlugin != null) {
        final result = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        granted = result ?? false;
      }
    }

    _logger.i('Notification permissions granted: $granted');
    return granted;
  }

  // HEALTH MODULE NOTIFICATIONS

  /// Schedules a single medication reminder notification at [time].
  ///
  /// The notification includes action buttons:
  /// - **"Taken ✓"** — marks the medication as taken via [onActionCallback].
  /// - **"Snooze 15 min"** — reschedules the notification 15 minutes later.
  ///
  /// [med] — the medication entity.
  /// [time] — the exact time to fire the notification.
  /// [timeIndex] — index of the time slot in `med.times` (for unique ID).
  /// [withFollowUp] — also schedule a one-shot follow-up notification
  /// [AppConstants.medicationFollowUpGraceMinutes] after [time].
  Future<void> scheduleMedicationReminder({
    required Medication med,
    required DateTime time,
    int timeIndex = 0,
    bool withFollowUp = false,
  }) async {
    final notifId = _medicationNotifId(med.id, timeIndex);

    await _notifications.zonedSchedule(
      id: notifId,
      title: 'Medication Reminder 💊',
      body: 'Time to take: ${med.name} — ${med.dosage}',
      scheduledDate: tz.TZDateTime.from(time, tz.local),
      notificationDetails: _medicationNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: '$kPayloadTypeMedication:${med.id}',
    );

    if (withFollowUp) {
      await scheduleMedicationFollowUp(
        med: med,
        followUpTime: time.add(
          const Duration(minutes: AppConstants.medicationFollowUpGraceMinutes),
        ),
        timeIndex: timeIndex,
      );
    }

    _logger.d(
      'Scheduled medication reminder: ${med.name} at $time (id=$notifId)',
    );
  }

  /// Schedules daily recurring reminders for a medication.
  ///
  /// Creates one notification per time slot in [med.times].
  /// Each time string is expected to be in "HH:mm" format.
  /// When [withFollowUps] is true, each slot also gets a recurring follow-up
  /// notification [AppConstants.medicationFollowUpGraceMinutes] later.
  Future<void> scheduleDailyMedicationReminders(
    Medication med, {
    bool withFollowUps = false,
  }) async {
    for (var i = 0; i < med.times.length; i++) {
      final timeParts = med.times[i].split(':');
      if (timeParts.length != 2) continue;

      final hour = int.tryParse(timeParts[0]);
      final minute = int.tryParse(timeParts[1]);
      if (hour == null || minute == null) continue;

      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If time already passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final notifId = _medicationNotifId(med.id, i);

      await _notifications.zonedSchedule(
        id: notifId,
        title: 'Medication Reminder 💊',
        body: 'Time to take: ${med.name} — ${med.dosage}',
        scheduledDate: scheduledDate,
        notificationDetails: _medicationNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: '$kPayloadTypeMedication:${med.id}',
        matchDateTimeComponents: DateTimeComponents.time,
      );

      if (withFollowUps) {
        await scheduleMedicationFollowUp(
          med: med,
          followUpTime: scheduledDate.add(
            const Duration(
              minutes: AppConstants.medicationFollowUpGraceMinutes,
            ),
          ),
          timeIndex: i,
        );
      }
    }

    _logger.d('Scheduled ${med.times.length} daily reminders for ${med.name}');
  }

  /// Schedules weekly recurring reminders for a medication.
  ///
  /// Creates one notification per time slot, repeating on the same day each week.
  /// When [withFollowUps] is true, each slot also gets a recurring follow-up
  /// notification [AppConstants.medicationFollowUpGraceMinutes] later.
  Future<void> scheduleWeeklyMedicationReminders(
    Medication med, {
    bool withFollowUps = false,
  }) async {
    for (var i = 0; i < med.times.length; i++) {
      final timeParts = med.times[i].split(':');
      if (timeParts.length != 2) continue;

      final hour = int.tryParse(timeParts[0]);
      final minute = int.tryParse(timeParts[1]);
      if (hour == null || minute == null) continue;

      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // Find the next occurrence of this day+time
      while (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final notifId = _medicationNotifId(med.id, i);

      await _notifications.zonedSchedule(
        id: notifId,
        title: 'Medication Reminder 💊',
        body: 'Time to take: ${med.name} — ${med.dosage}',
        scheduledDate: scheduledDate,
        notificationDetails: _medicationNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: '$kPayloadTypeMedication:${med.id}',
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );

      if (withFollowUps) {
        await scheduleMedicationFollowUp(
          med: med,
          followUpTime: scheduledDate.add(
            const Duration(
              minutes: AppConstants.medicationFollowUpGraceMinutes,
            ),
          ),
          timeIndex: i,
        );
      }
    }

    _logger.d('Scheduled ${med.times.length} weekly reminders for ${med.name}');
  }

  /// Schedules the follow-up ("did you log it?") notification paired with
  /// a medication reminder time slot.
  ///
  /// [followUpTime] is the absolute fire time (dose time + grace period).
  /// The recurrence mirrors the reminder's recurrence, derived from
  /// [Medication.frequency]: daily-style frequencies repeat every day,
  /// weekly repeats on the same weekday, monthly/as-needed are one-shot.
  ///
  /// The notification ID is derived deterministically from the reminder ID
  /// (see [kMedicationFollowUpIdOffset]) so it can be cancelled when the
  /// user logs the dose.
  Future<void> scheduleMedicationFollowUp({
    required Medication med,
    required DateTime followUpTime,
    int timeIndex = 0,
  }) async {
    final notifId = _medicationFollowUpNotifId(med.id, timeIndex);
    final l10n = _scheduledLocalizations();

    await _notifications.zonedSchedule(
      id: notifId,
      title: l10n.medicationFollowUpTitle,
      body: l10n.medicationFollowUpBody(med.name),
      scheduledDate: tz.TZDateTime.from(followUpTime, tz.local),
      notificationDetails: _medicationNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: '$kPayloadTypeMedication:${med.id}',
      matchDateTimeComponents: _followUpRecurrence(med.frequency),
    );

    _logger.d(
      'Scheduled medication follow-up: ${med.name} at $followUpTime '
      '(id=$notifId)',
    );
  }

  /// Shows a notification for a missed medication.
  ///
  /// Called by WorkManager hourly check (background_service.dart).
  Future<void> showMissedMedicationNotification({
    required int medicationId,
    required String medicationName,
    required String scheduledTime,
  }) async {
    // Use a high offset to avoid ID collision with scheduled reminders
    final notifId = 50000 + medicationId;

    await _notifications.show(
      id: notifId,
      title: 'Missed Medication ⚠️',
      body: 'You missed $medicationName scheduled at $scheduledTime',
      notificationDetails: _medicationNotificationDetails(),
      payload: '$kPayloadTypeMedication:$medicationId',
    );

    _logger.d('Showed missed medication notification for $medicationName');
  }

  /// Shows the daily summary notification at 21:00.
  ///
  /// [taken] — number of medications taken today.
  /// [missed] — number of medications missed today.
  /// [total] — total medications scheduled today.
  Future<void> showDailySummary({
    required int taken,
    required int missed,
    required int total,
  }) async {
    final percentage = total > 0 ? ((taken / total) * 100).round() : 0;
    final emoji = percentage == 100
        ? '🎉'
        : percentage >= 80
        ? '👍'
        : '📋';

    await _notifications.show(
      id: 90000, // Fixed ID for daily summary
      title: 'Daily Summary $emoji',
      body:
          'Medications: $taken/$total taken ($percentage%). '
          '${missed > 0 ? '$missed missed.' : 'Perfect compliance!'}',
      notificationDetails: _insightNotificationDetails(),
      payload: kPayloadTypeDailySummary,
    );

    _logger.d('Showed daily summary: $taken/$total');
  }

  /// Cancels all medication reminders for a specific medication.
  ///
  /// Cancels up to 10 time slot notifications per medication
  /// (covers the maximum realistic number of daily doses),
  /// along with their paired follow-up notifications.
  Future<void> cancelMedicationReminders(int medicationId) async {
    for (var i = 0; i < 10; i++) {
      await _notifications.cancel(id: _medicationNotifId(medicationId, i));
    }
    await cancelMedicationFollowUps(medicationId);
    // Also cancel any missed notification
    await _notifications.cancel(id: 50000 + medicationId);

    _logger.d('Cancelled all reminders for medication $medicationId');
  }

  /// Cancels the pending follow-up notification for a single dose slot.
  Future<void> cancelMedicationFollowUp(int medicationId, int timeIndex) async {
    await _notifications.cancel(
      id: _medicationFollowUpNotifId(medicationId, timeIndex),
    );

    _logger.d(
      'Cancelled follow-up for medication $medicationId slot $timeIndex',
    );
  }

  /// Cancels all follow-up notifications for a specific medication.
  ///
  /// Mirrors [cancelMedicationReminders]'s 10-slot coverage.
  Future<void> cancelMedicationFollowUps(int medicationId) async {
    for (var i = 0; i < 10; i++) {
      await _notifications.cancel(
        id: _medicationFollowUpNotifId(medicationId, i),
      );
    }

    _logger.d('Cancelled all follow-ups for medication $medicationId');
  }

  /// Schedules the one-shot post-meal measurement reminder for [mealId].
  ///
  /// [remindAt] is the absolute fire time (meal time plus
  /// [AppConstants.postMealReminderDelayHours]). One-shot on purpose: the
  /// trigger is a single logged meal, never a recurrence and never a reading.
  ///
  /// The notification only asks for a measurement. It says nothing about what
  /// a reading would mean, and nothing about the meal — not even its name,
  /// which would put health data on the lock screen.
  Future<void> schedulePostMealGlucoseReminder({
    required int mealId,
    required DateTime remindAt,
  }) async {
    final notifId = _postMealReminderNotifId(mealId);
    final l10n = _scheduledLocalizations();

    await _notifications.zonedSchedule(
      id: notifId,
      title: l10n.postMealReminderTitle,
      body: l10n.postMealReminderBody,
      scheduledDate: tz.TZDateTime.from(remindAt, tz.local),
      notificationDetails: _glucoseReminderNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload:
          '$kPayloadTypeGlucoseReminder:'
          '${remindAt.millisecondsSinceEpoch}',
    );

    // The meal id is safe to log; the meal itself is not.
    _logger.d('Scheduled post-meal reminder for meal $mealId (id=$notifId)');
  }

  /// Cancels the post-meal measurement reminder for [mealId].
  Future<void> cancelPostMealGlucoseReminder(int mealId) async {
    await _notifications.cancel(id: _postMealReminderNotifId(mealId));

    _logger.d('Cancelled post-meal reminder for meal $mealId');
  }

  // FITNESS MODULE NOTIFICATIONS

  /// Schedules a workout reminder notification.
  ///
  /// [templateName] — the workout template name (e.g. "Push Day").
  /// [time] — when to fire the reminder.
  Future<void> showWorkoutReminder({
    required String templateName,
    required DateTime time,
  }) async {
    final notifId = 60000 + templateName.hashCode.abs() % 10000;

    await _notifications.zonedSchedule(
      id: notifId,
      title: 'Workout Reminder 💪',
      body: 'Time for: $templateName',
      scheduledDate: tz.TZDateTime.from(time, tz.local),
      notificationDetails: _workoutNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: '$kPayloadTypeWorkout:$templateName',
    );

    _logger.d('Scheduled workout reminder: $templateName at $time');
  }

  /// Shows a streak warning notification.
  ///
  /// Fires when the user hasn't worked out today and their streak
  /// is at risk of breaking. Called from background task at 20:00.
  Future<void> showStreakWarning(int currentStreak) async {
    if (currentStreak <= 0) return;

    await _notifications.show(
      id: 70000,
      title: 'Streak at Risk! 🔥',
      body:
          'Your $currentStreak-day streak is about to break. '
          'Log a workout today to keep it going!',
      notificationDetails: _workoutNotificationDetails(),
      payload: '$kPayloadTypeStreak:$currentStreak',
    );

    _logger.d('Showed streak warning: $currentStreak days');
  }

  /// Shows a PR celebration notification.
  ///
  /// Fired immediately when the user achieves a new personal record.
  Future<void> showPRCelebration({
    required String exerciseName,
    required double weight,
  }) async {
    final notifId = 71000 + exerciseName.hashCode.abs() % 1000;

    await _notifications.show(
      id: notifId,
      title: 'New Personal Record! 🏆',
      body: 'You hit ${weight.toStringAsFixed(1)}kg on $exerciseName!',
      notificationDetails: _achievementNotificationDetails(),
      payload: '$kPayloadTypePersonalRecord:$exerciseName',
    );

    _logger.d('Showed PR celebration: $exerciseName @ ${weight}kg');
  }

  // INSIGHT MODULE NOTIFICATIONS

  /// Shows a notification that the weekly report is ready.
  ///
  /// Fired on Monday morning via WorkManager.
  Future<void> showWeeklyReportReady() async {
    await _notifications.show(
      id: 80000,
      title: 'Weekly Report Ready 📊',
      body:
          'Your health & fitness summary for last week is ready. '
          'Tap to view your progress!',
      notificationDetails: _insightNotificationDetails(),
      payload: kPayloadTypeWeeklyReport,
    );

    _logger.d('Showed weekly report ready notification');
  }

  /// Shows a notification for an important insight.
  ///
  /// Only fires for [InsightPriority.high] or [InsightPriority.critical].
  Future<void> showImportantInsight(Insight insight) async {
    if (insight.priority.value < InsightPriority.high.value) return;

    final notifId = 81000 + insight.id.abs() % 1000;

    await _notifications.show(
      id: notifId,
      title:
          '${insight.priority == InsightPriority.critical ? '🚨' : '💡'} '
          '${insight.title}',
      body: insight.message,
      notificationDetails: _insightNotificationDetails(),
      payload: '$kPayloadTypeInsight:${insight.id}',
    );

    _logger.d('Showed important insight notification: ${insight.title}');
  }

  /// Announces a freshly unlocked [achievement].
  ///
  /// The text is resolved here rather than by the caller because unlocks are
  /// detected in a service with no widget context — the same reason
  /// [_scheduledLocalizations] exists. The achievement's own name and
  /// requirement are the whole message; nothing about the user's health data
  /// goes on the lock screen.
  Future<void> showAchievementUnlocked(Achievement achievement) async {
    final l10n = _scheduledLocalizations();

    await showNotification(
      id: kAchievementNotificationIdOffset + achievement.id,
      title: l10n.achievementUnlockedTitle,
      body:
          '${achievement.localizedTitle(l10n)} — '
          '${achievement.localizedDescription(l10n)}',
      payload: '$kPayloadTypeAchievement:${achievement.id}',
    );

    _logger.d('Showed achievement unlock: ${achievement.iconName}');
  }

  // GENERAL NOTIFICATIONS

  /// Shows an immediate notification.
  ///
  /// [id] - Unique notification ID
  /// [title] - Notification title
  /// [body] - Notification body
  /// [payload] - Optional payload data for deep linking
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _notifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _defaultNotificationDetails(),
      payload: payload,
    );
  }

  /// Cancels a specific notification by ID.
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id: id);
  }

  /// Cancels all scheduled and active notifications.
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    _logger.i('All notifications cancelled');
  }

  // NOTIFICATION ID MANAGEMENT

  /// Generates a unique notification ID for medication reminders.
  ///
  /// ID ranges:
  /// - `0–49999`: Scheduled medication reminders (medId * 100 + timeIndex)
  /// - `50000–59999`: Missed medication notifications
  /// - `60000–69999`: Workout reminders
  /// - `70000–79999`: Streak/fitness notifications
  /// - `80000–89999`: Insight/report notifications
  /// - `90000–99999`: Summary/system notifications
  /// - `100000–149999`: Medication dose follow-ups
  ///   ([kMedicationFollowUpIdOffset] + reminder ID)
  /// - `150000–159999`: Post-meal measurement reminders
  ///   ([kPostMealReminderIdOffset] + meal ID)
  int _medicationNotifId(int medId, int timeIndex) {
    return (medId.abs() % 500) * 100 + (timeIndex.clamp(0, 99));
  }

  /// Derives the follow-up notification ID from the reminder ID scheme.
  int _medicationFollowUpNotifId(int medId, int timeIndex) {
    return kMedicationFollowUpIdOffset + _medicationNotifId(medId, timeIndex);
  }

  /// Derives the post-meal reminder notification ID from the meal ID.
  ///
  /// Wrapped into a 10 000-wide slot so the ID stays inside the range
  /// documented above; a collision would need 10 000 meals between two
  /// pending reminders, which cannot happen with a 2-hour lifetime.
  int _postMealReminderNotifId(int mealId) {
    return kPostMealReminderIdOffset + (mealId.abs() % 10000);
  }

  /// Returns the recurrence rule for a follow-up so it mirrors the
  /// recurrence of the reminder it is paired with.
  DateTimeComponents? _followUpRecurrence(MedicationFrequency frequency) {
    switch (frequency) {
      case MedicationFrequency.daily:
      case MedicationFrequency.twiceDaily:
      case MedicationFrequency.threeTimesDaily:
        return DateTimeComponents.time;
      case MedicationFrequency.weekly:
        return DateTimeComponents.dayOfWeekAndTime;
      case MedicationFrequency.monthly:
      case MedicationFrequency.asNeeded:
        // Monthly reminders are scheduled as one-shots; mirror that.
        return null;
    }
  }

  /// Resolves localized strings for notifications scheduled without a
  /// widget context. Falls back to English if no resolver is configured
  /// or resolution fails (e.g. unsupported stored locale).
  AppLocalizations _scheduledLocalizations() {
    try {
      return _resolveLocalizations?.call() ??
          lookupAppLocalizations(const Locale('en'));
    } catch (_) {
      return lookupAppLocalizations(const Locale('en'));
    }
  }

  // NOTIFICATION CHANNELS (Android)

  /// Creates all notification channels for Android.
  Future<void> _createNotificationChannels() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin == null) return;

    // Medication channel — high importance, sound + vibration
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        AppConstants.notificationChannelMedication,
        AppConstants.notificationChannelMedicationName,
        description: 'Notifications for medication reminders',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );

    // Workout channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        AppConstants.notificationChannelWorkout,
        AppConstants.notificationChannelWorkoutName,
        description: 'Notifications for workout reminders and streak alerts',
        importance: Importance.defaultImportance,
        playSound: true,
      ),
    );

    // Achievement channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        AppConstants.notificationChannelAchievement,
        AppConstants.notificationChannelAchievementName,
        description: 'Notifications for unlocked achievements and PRs',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );

    // Insight channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        AppConstants.notificationChannelInsight,
        AppConstants.notificationChannelInsightName,
        description: 'Notifications for insights and weekly reports',
        importance: Importance.defaultImportance,
      ),
    );

    // Post-meal measurement reminder channel — its own channel so it can be
    // silenced from the OS without touching medication reminders.
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        AppConstants.notificationChannelGlucoseReminder,
        AppConstants.notificationChannelGlucoseReminderName,
        description: 'Reminders to add a measurement after a logged meal',
        importance: Importance.defaultImportance,
        playSound: true,
      ),
    );

    // General channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        AppConstants.notificationChannelGeneral,
        AppConstants.notificationChannelGeneralName,
        description: 'General app notifications',
        importance: Importance.defaultImportance,
      ),
    );

    _logger.d('Android notification channels created');
  }

  // NOTIFICATION DETAILS (per channel)

  /// Returns notification details for medication reminders.
  ///
  /// Includes action buttons for "Taken" and "Snooze 15 min" on Android.
  NotificationDetails _medicationNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        AppConstants.notificationChannelMedication,
        AppConstants.notificationChannelMedicationName,
        channelDescription: 'Notifications for medication reminders',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.reminder,
        actions: [
          AndroidNotificationAction(
            kActionMedicationTaken,
            'Taken ✓',
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            kActionMedicationSnooze,
            'Snooze 15 min',
            showsUserInterface: false,
          ),
        ],
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: kCategoryMedication,
      ),
    );
  }

  /// Returns notification details for workout reminders.
  NotificationDetails _workoutNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        AppConstants.notificationChannelWorkout,
        AppConstants.notificationChannelWorkoutName,
        channelDescription: 'Notifications for workout reminders',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  /// Returns notification details for achievements and PRs.
  NotificationDetails _achievementNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        AppConstants.notificationChannelAchievement,
        AppConstants.notificationChannelAchievementName,
        channelDescription: 'Notifications for achievements and PRs',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  /// Returns notification details for post-meal measurement reminders.
  ///
  /// Deliberately plain: no action buttons and no category. The only thing
  /// this notification can do is open the entry form.
  NotificationDetails _glucoseReminderNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        AppConstants.notificationChannelGlucoseReminder,
        AppConstants.notificationChannelGlucoseReminderName,
        channelDescription:
            'Reminders to add a measurement after a logged meal',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        playSound: true,
        category: AndroidNotificationCategory.reminder,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  /// Returns notification details for insights and reports.
  NotificationDetails _insightNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        AppConstants.notificationChannelInsight,
        AppConstants.notificationChannelInsightName,
        channelDescription: 'Notifications for insights and weekly reports',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  /// Returns default notification details.
  NotificationDetails _defaultNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        AppConstants.notificationChannelGeneral,
        AppConstants.notificationChannelGeneralName,
        channelDescription: 'General app notifications',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  // DEEP LINK ROUTING & ACTION HANDLING

  /// Handles notification tap and action button events.
  ///
  /// Payload format: `type:id` (e.g. `medication:123`, `workout:PushDay`,
  /// `insight:42`, `weekly_report`, `streak:15`, `pr:BenchPress`,
  /// `daily_summary`).
  ///
  /// If the response contains an actionId, it's an action button tap;
  /// otherwise it's a regular notification tap.
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    final actionId = response.actionId;

    // Handle action button taps (Taken / Snooze)
    if (actionId != null && actionId.isNotEmpty) {
      _handleNotificationAction(actionId, payload);
      return;
    }

    // Handle regular notification tap — navigate via deep link
    if (payload == null || payload.isEmpty) return;

    _logger.d('Notification tapped with payload: $payload');

    // Parse payload into type:id
    final parts = payload.split(':');
    final type = parts[0];
    final id = parts.length > 1 ? parts.sublist(1).join(':') : '';

    // Fire analytics event
    _analyticsService.logNotificationTapped(notificationType: type);

    // Invoke navigation callback
    onNavigationCallback?.call(type, id);
  }

  /// Handles notification action button taps.
  void _handleNotificationAction(String actionId, String? payload) {
    _logger.d('Notification action: $actionId, payload: $payload');

    switch (actionId) {
      case kActionMedicationTaken:
        _analyticsService.logNotificationTapped(
          notificationType: 'medication_taken_action',
        );
        onActionCallback?.call(actionId, payload);

      case kActionMedicationSnooze:
        _analyticsService.logNotificationTapped(
          notificationType: 'medication_snooze_action',
        );
        onActionCallback?.call(actionId, payload);

      default:
        _logger.w('Unknown notification action: $actionId');
    }
  }
}
