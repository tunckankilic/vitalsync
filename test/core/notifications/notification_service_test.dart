import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:vitalsync/core/analytics/analytics_service.dart';
import 'package:vitalsync/core/constants/app_constants.dart';
import 'package:vitalsync/core/enums/medication_frequency.dart';
import 'package:vitalsync/core/notifications/notification_service.dart';
import 'package:vitalsync/domain/entities/health/medication.dart';

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

typedef ScheduledNotification = ({
  int id,
  tz.TZDateTime date,
  DateTimeComponents? match,
  String? title,
  String? body,
});

void main() {
  late NotificationService service;
  late MockFlutterLocalNotificationsPlugin mockPlugin;
  late MockAnalyticsService mockAnalytics;
  late List<ScheduledNotification> schedules;

  setUpAll(() {
    tzdata.initializeTimeZones();
    registerFallbackValue(tz.TZDateTime(tz.local, 2024));
    registerFallbackValue(const NotificationDetails());
    registerFallbackValue(AndroidScheduleMode.exactAllowWhileIdle);
  });

  setUp(() {
    mockPlugin = MockFlutterLocalNotificationsPlugin();
    mockAnalytics = MockAnalyticsService();
    schedules = [];
    service = NotificationService(
      notifications: mockPlugin,
      analyticsService: mockAnalytics,
    );

    when(
      () => mockPlugin.zonedSchedule(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        scheduledDate: any(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: any(named: 'androidScheduleMode'),
        payload: any(named: 'payload'),
        matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
      ),
    ).thenAnswer((invocation) async {
      final args = invocation.namedArguments;
      schedules.add((
        id: args[#id] as int,
        title: args[#title] as String?,
        body: args[#body] as String?,
        date: args[#scheduledDate] as tz.TZDateTime,
        match: args[#matchDateTimeComponents] as DateTimeComponents?,
      ));
    });
    when(
      () => mockPlugin.cancel(id: any(named: 'id')),
    ).thenAnswer((_) async {});
  });

  final testMedication = Medication(
    id: 1,
    name: 'Aspirin',
    dosage: '100mg',
    frequency: MedicationFrequency.daily,
    times: ['08:00'],
    startDate: DateTime(2023, 1, 1),
    color: 0xFF000000,
    isActive: true,
    lastModifiedAt: DateTime.now(),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  // Reminder ID for medId=1, timeIndex=0: (1 % 500) * 100 + 0 = 100
  const reminderId = 100;
  const followUpId = kMedicationFollowUpIdOffset + reminderId;

  group('follow-up scheduling', () {
    test(
      'daily reminders with follow-ups schedule a paired follow-up '
      '${AppConstants.medicationFollowUpGraceMinutes} minutes later',
      () async {
        await service.scheduleDailyMedicationReminders(
          testMedication,
          withFollowUps: true,
        );

        
        expect(schedules, hasLength(2));

        final reminder = schedules.firstWhere((s) => s.id == reminderId);
        final followUp = schedules.firstWhere((s) => s.id == followUpId);

        expect(
          followUp.date.difference(reminder.date),
          const Duration(
            minutes: AppConstants.medicationFollowUpGraceMinutes,
          ),
        );
        // Follow-up recurrence mirrors the daily reminder
        expect(followUp.match, DateTimeComponents.time);
        // English fallback localization includes the medication name
        expect(followUp.body, contains('Aspirin'));
        expect(followUp.body, contains("Don't forget to log it"));
      },
    );

    test('daily reminders without follow-ups schedule only the reminder', () async {
      await service.scheduleDailyMedicationReminders(testMedication);

      
      expect(schedules, hasLength(1));
      expect(schedules.single.id, reminderId);
    });

    test('weekly follow-ups repeat on day-of-week and time', () async {
      final weeklyMed = testMedication.copyWith(
        frequency: MedicationFrequency.weekly,
      );

      await service.scheduleWeeklyMedicationReminders(
        weeklyMed,
        withFollowUps: true,
      );

      final followUp = schedules.firstWhere(
        (s) => s.id == followUpId,
      );
      expect(followUp.match, DateTimeComponents.dayOfWeekAndTime);
    });

    test('one-shot reminder follow-up does not recur (monthly)', () async {
      final monthlyMed = testMedication.copyWith(
        frequency: MedicationFrequency.monthly,
      );

      await service.scheduleMedicationReminder(
        med: monthlyMed,
        time: DateTime.now().add(const Duration(days: 1)),
        withFollowUp: true,
      );

      final followUp = schedules.firstWhere(
        (s) => s.id == followUpId,
      );
      expect(followUp.match, isNull);
    });

    test('follow-up IDs stay in their reserved range for multi-slot meds', () async {
      final multiDoseMed = testMedication.copyWith(
        frequency: MedicationFrequency.threeTimesDaily,
        times: ['08:00', '14:00', '20:00'],
      );

      await service.scheduleDailyMedicationReminders(
        multiDoseMed,
        withFollowUps: true,
      );

      
      final reminderIds = schedules
          .where((s) => s.id < kMedicationFollowUpIdOffset)
          .map((s) => s.id)
          .toList();
      final followUpIds = schedules
          .where((s) => s.id >= kMedicationFollowUpIdOffset)
          .map((s) => s.id)
          .toList();

      expect(reminderIds, [100, 101, 102]);
      expect(followUpIds, [100100, 100101, 100102]);
      // Each follow-up ID is derived from its reminder ID
      for (final id in followUpIds) {
        expect(
          reminderIds,
          contains(id - kMedicationFollowUpIdOffset),
        );
      }
    });
  });

  group('follow-up cancellation', () {
    test('cancelMedicationReminders also cancels follow-up IDs', () async {
      await service.cancelMedicationReminders(1);

      final cancelled = verify(
        () => mockPlugin.cancel(id: captureAny(named: 'id')),
      ).captured.cast<int>();

      // Reminder slots, follow-up slots and the missed notification
      for (var i = 0; i < 10; i++) {
        expect(cancelled, contains(reminderId + i));
        expect(cancelled, contains(followUpId + i));
      }
      expect(cancelled, contains(50001));
    });

    test('cancelMedicationFollowUp cancels the derived follow-up ID', () async {
      await service.cancelMedicationFollowUp(1, 0);

      verify(() => mockPlugin.cancel(id: followUpId)).called(1);
      verifyNoMoreInteractions(mockPlugin);
    });

    test('cancelMedicationFollowUps covers all 10 slots', () async {
      await service.cancelMedicationFollowUps(1);

      final cancelled = verify(
        () => mockPlugin.cancel(id: captureAny(named: 'id')),
      ).captured.cast<int>();

      expect(
        cancelled,
        List.generate(10, (i) => followUpId + i),
      );
    });
  });
}
