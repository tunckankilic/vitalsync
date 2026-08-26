// Notification tap destinations, checked against the real route table.
//
// The failure this guards against is silent: a notification whose destination
// does not exist opens go_router's "no routes for location" page, and nothing
// in a build or an analyze run says so. `/insights/weekly-report` was pushed
// from two dashboard cards for two releases with no route behind it — this
// suite exists so a notification cannot repeat that.

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vitalsync/core/notifications/notification_service.dart';
import 'package:vitalsync/core/router/app_router.dart';
import 'package:vitalsync/core/router/notification_routes.dart';
import 'package:vitalsync/domain/models/app_user.dart';
import 'package:vitalsync/domain/repositories/shared/auth_repository.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  setUpAll(() {
    // `appRouter` resolves AuthRepository at construction for its
    // refreshListenable, so GetIt has to answer before the route table can be
    // read. The stream stays empty; nothing here navigates.
    final auth = _MockAuthRepository();
    when(() => auth.authStateChanges).thenAnswer(
      (_) => const Stream<AppUser?>.empty(),
    );
    when(() => auth.currentUser).thenReturn(null);
    GetIt.instance.registerSingleton<AuthRepository>(auth);
  });

  tearDownAll(() => GetIt.instance.reset());

  group('notificationDestinationFor', () {
    test('opens the entry form with the fire time for a glucose reminder', () {
      final at = DateTime.utc(2026, 3, 1, 14).millisecondsSinceEpoch;

      expect(
        notificationDestinationFor(kPayloadTypeGlucoseReminder, '$at'),
        NotificationDestination(
          '/health/glucose/add?at=$at',
          NotificationNavigation.push,
        ),
      );
    });

    test('opens the plain entry form when the fire time is unparseable', () {
      expect(
        notificationDestinationFor(kPayloadTypeGlucoseReminder, 'not-a-number'),
        const NotificationDestination(
          '/health/glucose/add',
          NotificationNavigation.push,
        ),
      );
    });

    test('opens the medication detail screen for its id', () {
      expect(
        notificationDestinationFor(kPayloadTypeMedication, '42'),
        const NotificationDestination(
          '/health/medications/42',
          NotificationNavigation.push,
        ),
      );
    });

    test('falls back to the health tab when the medication id is junk', () {
      expect(
        notificationDestinationFor(kPayloadTypeMedication, ''),
        const NotificationDestination('/health', NotificationNavigation.go),
      );
    });

    test('enters tab roots with go, not push', () {
      // Pushing a shell branch stacks a second copy of the tab on top of the
      // current screen instead of switching to it.
      for (final type in [
        kPayloadTypeDailySummary,
        kPayloadTypeStreak,
        kPayloadTypeMedication,
      ]) {
        final destination = notificationDestinationFor(type, '');
        expect(
          destination!.navigation,
          NotificationNavigation.go,
          reason: '$type resolves to a bottom-navigation tab root',
        );
      }
    });

    test('has no destination for an unknown type', () {
      expect(notificationDestinationFor('not_a_payload_type', '1'), isNull);
    });
  });

  group('coverage of every payload type', () {
    test('each emitted type is either routed or explicitly declined', () {
      for (final type in kNotificationPayloadTypes) {
        final destination = notificationDestinationFor(type, '1');

        if (kUnroutedNotificationPayloadTypes.contains(type)) {
          expect(
            destination,
            isNull,
            reason:
                '$type is listed as unrouted but resolves to a destination; '
                'remove it from kUnroutedNotificationPayloadTypes',
          );
        } else {
          expect(
            destination,
            isNotNull,
            reason:
                '$type has no destination. Either route it in '
                'notificationDestinationFor or add it to '
                'kUnroutedNotificationPayloadTypes with a reason',
          );
        }
      }
    });

    test('every declined type is one the service can actually emit', () {
      for (final type in kUnroutedNotificationPayloadTypes) {
        expect(
          kNotificationPayloadTypes,
          contains(type),
          reason: '$type is declined but no longer emitted — drop it',
        );
      }
    });
  });

  group('destinations resolve against the router', () {
    test('every destination matches a real route', () {
      // The ids are arbitrary but must parse, so the id-carrying types produce
      // their real location shape rather than a fallback.
      for (final type in kNotificationPayloadTypes) {
        final destination = notificationDestinationFor(type, '7');
        if (destination == null) continue;

        final match = appRouter.configuration.findMatch(
          Uri.parse(destination.location),
        );

        expect(
          match.isError,
          isFalse,
          reason:
              '$type points at ${destination.location}, which no route in '
              'app_router.dart matches. A tap on it would land on '
              "go_router's error page.",
        );
      }
    });

    test('the weekly report route the dashboard pushes exists', () {
      // greeting_card.dart and quick_actions_card.dart have pushed this path
      // since before 1.0.0; the route behind it only landed in 1.1.0.
      final match = appRouter.configuration.findMatch(
        Uri.parse('/insights/weekly-report'),
      );

      expect(match.isError, isFalse);
    });
  });
}
