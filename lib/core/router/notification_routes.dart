/// VitalSync — where a notification tap lands.
///
/// The mapping lives here rather than inline in `main.dart` so it can be tested
/// against the real route table. A destination that does not resolve fails
/// silently at runtime: the user taps, the app opens, and go_router shows its
/// "no routes for location" page. `/insights/weekly-report` was pushed from two
/// dashboard cards for two releases with no route behind it, which is precisely
/// this failure — `notification_routes_test.dart` exists so it cannot happen
/// again through a notification.
library;

import '../notifications/notification_service.dart';

/// How a destination should be entered.
enum NotificationNavigation {
  /// Pushed on top of whatever is on screen. For detail screens the user is
  /// expected to come back from.
  push,

  /// Replaces the current location. Required for the bottom-navigation tab
  /// roots (`/dashboard`, `/health`, `/fitness`) — pushing one stacks a second
  /// copy of the tab on top of the current screen.
  go,
}

/// A notification tap's destination.
class NotificationDestination {
  const NotificationDestination(this.location, this.navigation);

  /// The go_router location to open.
  final String location;

  /// Whether [location] is pushed or navigated to.
  final NotificationNavigation navigation;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationDestination &&
          other.location == location &&
          other.navigation == navigation;

  @override
  int get hashCode => Object.hash(location, navigation);

  @override
  String toString() => 'NotificationDestination($location, ${navigation.name})';
}

/// Payload types that are known but deliberately have no destination.
///
/// Kept as a named set rather than a `default: return null` so that a type
/// nobody thought about shows up as a test failure instead of as a tap that
/// does nothing.
const Set<String> kUnroutedNotificationPayloadTypes = {
  // There is no insight screen to open: the unreachable insight UI was removed
  // before 1.1.0 (docs/INSIGHTS_UI.md) and NotificationService's
  // showInsightNotification has no caller either. Restore both together.
  kPayloadTypeInsight,
};

/// Resolves a notification payload to the screen its tap should open.
///
/// [type] and [id] are the two halves of the payload split on its first `:`
/// (see [NotificationService] for each type's shape). Returns null for a type
/// with no destination — see [kUnroutedNotificationPayloadTypes].
NotificationDestination? notificationDestinationFor(String type, String id) {
  switch (type) {
    // The id is the reminder's fire time in millisecondsSinceEpoch. It is
    // forwarded so the entry form opens with the measurement time pre-filled;
    // no meal or reading data travels in the payload.
    case kPayloadTypeGlucoseReminder:
      final at = int.tryParse(id);
      return NotificationDestination(
        at == null ? '/health/glucose/add' : '/health/glucose/add?at=$at',
        NotificationNavigation.push,
      );

    // Reminders and their follow-ups both carry the medication id, and the
    // detail screen is where a dose gets logged. An unparseable id falls back
    // to the list rather than opening a detail screen for medication 0.
    case kPayloadTypeMedication:
      final medicationId = int.tryParse(id);
      return medicationId == null
          ? const NotificationDestination('/health', NotificationNavigation.go)
          : NotificationDestination(
              '/health/medications/$medicationId',
              NotificationNavigation.push,
            );

    case kPayloadTypeDailySummary:
      return const NotificationDestination(
        '/dashboard',
        NotificationNavigation.go,
      );

    // The streak warning exists to get a workout started, so it lands on the
    // screen that can start one rather than on a history view.
    case kPayloadTypeStreak:
      return const NotificationDestination(
        '/fitness',
        NotificationNavigation.go,
      );

    case kPayloadTypeWeeklyReport:
      return const NotificationDestination(
        '/insights/weekly-report',
        NotificationNavigation.push,
      );

    // No per-achievement route exists; the list is the destination.
    case kPayloadTypeAchievement:
      return const NotificationDestination(
        '/fitness/achievements',
        NotificationNavigation.push,
      );

    // The next two have no caller yet. Routed anyway so that adding the caller
    // is all it takes — see the constants' docs in NotificationService.
    case kPayloadTypeWorkout:
      return const NotificationDestination(
        '/fitness/templates',
        NotificationNavigation.push,
      );

    case kPayloadTypePersonalRecord:
      return const NotificationDestination(
        '/fitness/progress',
        NotificationNavigation.push,
      );

    default:
      return null;
  }
}
