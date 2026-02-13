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

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/health/medication.dart';
import '../../domain/entities/insights/insight.dart';
import '../analytics/analytics_service.dart';
import '../constants/app_constants.dart';
import '../enums/insight_priority.dart';

// Notification Action Identifiers

/// Action ID when user taps "Taken" on a medication notification.
const String kActionMedicationTaken = 'medication_taken';

/// Action ID when user taps "Snooze 15 min" on a medication notification.
const String kActionMedicationSnooze = 'medication_snooze';

/// Android notification action category for medication reminders.
const String kCategoryMedication = 'medication_category';

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
    Logger? logger,
  }) : _notifications = notifications,
       _analyticsService = analyticsService,
       _logger = logger ?? Logger();

  final FlutterLocalNotificationsPlugin _notifications;
  final AnalyticsService _analyticsService;
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
  Future<void> scheduleMedicationReminder({
    required Medication med,
    required DateTime time,
    int timeIndex = 0,
  }) async {
    final notifId = _medicationNotifId(med.id, timeIndex);

    await _notifications.zonedSchedule(
      id: notifId,
      title: 'Medication Reminder 💊',
      body: 'Time to take: ${med.name} — ${med.dosage}',
      scheduledDate: tz.TZDateTime.from(time, tz.local),
      notificationDetails: _medicationNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'medication:${med.id}',
    );

    _logger.d(
      'Scheduled medication reminder: ${med.name} at $time (id=$notifId)',
    );
  }

  /// Schedules daily recurring reminders for a medication.
  ///
  /// Creates one notification per time slot in [med.times].
  /// Each time string is expected to be in "HH:mm" format.
  Future<void> scheduleDailyMedicationReminders(Medication med) async {
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
        payload: 'medication:${med.id}',
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }

    _logger.d('Scheduled ${med.times.length} daily reminders for ${med.name}');
  }

  /// Schedules weekly recurring reminders for a medication.
  ///
  /// Creates one notification per time slot, repeating on the same day each week.
  Future<void> scheduleWeeklyMedicationReminders(Medication med) async {
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
        payload: 'medication:${med.id}',
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }

    _logger.d('Scheduled ${med.times.length} weekly reminders for ${med.name}');
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
      payload: 'medication:$medicationId',
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
      payload: 'daily_summary',
    );

    _logger.d('Showed daily summary: $taken/$total');
  }

  /// Cancels all medication reminders for a specific medication.
  ///
  /// Cancels up to 10 time slot notifications per medication
  /// (covers the maximum realistic number of daily doses).
  Future<void> cancelMedicationReminders(int medicationId) async {
    for (var i = 0; i < 10; i++) {
      await _notifications.cancel(id: _medicationNotifId(medicationId, i));
    }
    // Also cancel any missed notification
    await _notifications.cancel(id: 50000 + medicationId);

    _logger.d('Cancelled all reminders for medication $medicationId');
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
      payload: 'workout:$templateName',
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
      payload: 'streak:$currentStreak',
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
      payload: 'pr:$exerciseName',
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
      payload: 'weekly_report',
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
      payload: 'insight:${insight.id}',
    );

    _logger.d('Showed important insight notification: ${insight.title}');
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
  /// - `90000+`: Summary/system notifications
  int _medicationNotifId(int medId, int timeIndex) {
    return (medId.abs() % 500) * 100 + (timeIndex.clamp(0, 99));
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
