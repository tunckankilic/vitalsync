/// Shared setup for the integration tests.
///
/// These run the real widget tree over the real Drift schema — an in-memory
/// database, but the same tables, DAOs, repositories and providers the app
/// uses. Only two things are stubbed, and both are platform edges rather
/// than app logic:
///
/// * [FlutterLocalNotificationsPlugin], because scheduling a notification
///   needs a live platform channel. The recording fake below lets a test
///   assert what WOULD have been scheduled.
/// * The cloud. Nothing here talks to Amplify: the sync queue is inspected
///   directly, which is where a push starts.
library;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:vitalsync/core/analytics/analytics_service.dart';
import 'package:vitalsync/core/enums/glucose_source.dart';
import 'package:vitalsync/core/l10n/app_localizations.dart';
import 'package:vitalsync/core/notifications/notification_service.dart';
import 'package:vitalsync/data/local/database.dart';
import 'package:vitalsync/data/repositories/health/glucose_repository_impl.dart';
import 'package:vitalsync/data/repositories/health/health_sample_repository_impl.dart';
import 'package:vitalsync/data/repositories/health/meal_repository_impl.dart';
import 'package:vitalsync/domain/entities/health/glucose_reading.dart';
import 'package:vitalsync/domain/repositories/health/glucose_repository.dart';
import 'package:vitalsync/domain/repositories/health/meal_repository.dart';
import 'package:vitalsync/features/health/domain/services/meal_data_coverage_service.dart';
import 'package:vitalsync/features/health/domain/services/post_meal_reminder_service.dart';
import 'package:vitalsync/features/health/presentation/providers/glucose_provider.dart';
import 'package:vitalsync/features/health/presentation/providers/meal_provider.dart';

/// One notification the app asked the platform to schedule.
typedef ScheduledNotification = ({int id, DateTime at, String? body});

/// Records scheduling instead of reaching the platform channel.
class RecordingNotificationsPlugin extends Fake
    implements FlutterLocalNotificationsPlugin {
  final List<ScheduledNotification> scheduled = [];
  final List<int> cancelled = [];

  @override
  Future<void> zonedSchedule({
    required int id,
    String? title,
    String? body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    scheduled.add((
      id: id,
      // Compared against local wall-clock times in the assertions.
      at: DateTime(
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        scheduledDate.hour,
        scheduledDate.minute,
      ),
      body: body,
    ));
  }

  @override
  Future<void> cancel({required int id, String? tag}) async {
    cancelled.add(id);
  }

  @override
  Future<void> cancelAll({String? tag}) async {}
}

/// Everything a test needs to drive the app's health module.
class TestApp {
  TestApp._(this.db, this.notifications, this.container);

  final AppDatabase db;
  final RecordingNotificationsPlugin notifications;
  final ProviderContainer container;

  MealRepository get mealRepository => container.read(mealRepositoryProvider);
  GlucoseRepository get glucoseRepository =>
      container.read(glucoseRepositoryProvider);

  Future<List<SyncQueueData>> pendingSyncItems() =>
      db.syncDao.getPendingItems();

  Future<void> dispose() async {
    container.dispose();
    await db.close();
  }
}

/// Builds the provider graph over a fresh in-memory database.
///
/// [remindersEnabled] mirrors the two settings switches that gate the
/// post-meal reminder, so a test can prove the off state schedules nothing.
TestApp buildTestApp({bool remindersEnabled = true}) {
  final db = AppDatabase(NativeDatabase.memory());
  final notifications = RecordingNotificationsPlugin();

  final mealRepository = MealRepositoryImpl(db.mealDao, db);
  final glucoseRepository = GlucoseRepositoryImpl(db.glucoseDao, db);
  final coverageService = MealDataCoverageService(
    mealRepository: mealRepository,
    glucoseRepository: glucoseRepository,
    healthSampleRepository: HealthSampleRepositoryImpl(db.healthSampleDao),
  );
  final notificationService = NotificationService(
    notifications: notifications,
    analyticsService: _NoopAnalytics(),
  );
  final reminderService = PostMealReminderService(
    notificationService: notificationService,
    mealRepository: mealRepository,
    areNotificationsEnabled: () => remindersEnabled,
    isReminderEnabled: () => remindersEnabled,
  );

  final container = ProviderContainer(
    overrides: [
      mealRepositoryProvider.overrideWithValue(mealRepository),
      glucoseRepositoryProvider.overrideWithValue(glucoseRepository),
      mealDataCoverageServiceProvider.overrideWithValue(coverageService),
      postMealReminderServiceProvider.overrideWithValue(reminderService),
    ],
  );

  return TestApp._(db, notifications, container);
}

/// Pumps [screen] inside the app's real localization and theme setup, on a
/// router that can be popped (the entry forms call `context.pop()`).
Future<void> pumpScreen(
  WidgetTester tester,
  TestApp app,
  Widget screen,
) async {
  await tester.binding.setSurfaceSize(const Size(1000, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final router = GoRouter(
    initialLocation: '/screen',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SizedBox.shrink()),
      GoRoute(path: '/screen', builder: (_, _) => screen),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: app.container,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The notification service logs a tap event; nothing here asserts on
/// analytics, so the calls are swallowed.
class _NoopAnalytics extends Fake implements AnalyticsService {
  @override
  Future<void> logNotificationTapped({String? notificationType}) async {}
}

/// A manual reading at [measuredAt], for tests that need data around a meal.
GlucoseReading manualReadingAt(DateTime measuredAt, {required double value}) {
  return GlucoseReading(
    id: 0,
    valueMgDl: value,
    measuredAt: measuredAt,
    source: GlucoseSource.manual,
    lastModifiedAt: measuredAt,
    createdAt: measuredAt,
  );
}
