// Screen tests for the weekly report.
//
// This screen had no coverage and, until 1.1.0, no route either — the two
// dashboard cards that pushed it landed on go_router's error page, so nobody
// had seen it in the app. Now that it is reachable, the defects 30557d1 fixed
// are worth pinning down, because every one of them rendered as a plausible
// number rather than an error:
//
//   * the cards read flat keys off an export-shaped JSON and showed zeros;
//   * the week selector moved its label but the provider always regenerated
//     the current week;
//   * the cross-module card printed a hardcoded "Best Day: Wednesday".

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vitalsync/core/enums/trend_direction.dart';
import 'package:vitalsync/domain/entities/insights/weekly_report.dart';
import 'package:vitalsync/features/insights/domain/weekly_report_service.dart';
import 'package:vitalsync/features/insights/presentation/providers/weekly_report_provider.dart';
import 'package:vitalsync/features/insights/presentation/screens/weekly_report_screen.dart';

import '../../../support/pump_app.dart';

class _MockWeeklyReportService extends Mock implements WeeklyReportService {}

void main() {
  late _MockWeeklyReportService service;

  setUpAll(() => registerFallbackValue(DateTime(2026)));

  setUp(() => service = _MockWeeklyReportService());

  WeeklyReport reportFor(
    DateTime weekStart, {
    DateTime? bestDay,
    int workoutCount = 3,
  }) {
    return WeeklyReport(
      startDate: weekStart,
      endDate: weekStart.add(const Duration(days: 6)),
      generatedAt: weekStart,
      medicationCompliance: 0.8,
      previousMedicationCompliance: 0.6,
      complianceTrendVsPrevious: TrendDirection.up,
      takenMedicationsCount: 12,
      missedMedicationsCount: 2,
      skippedMedicationsCount: 1,
      symptomsLoggedCount: 4,
      workoutCount: workoutCount,
      totalVolume: 4200,
      volumeTrendVsPrevious: TrendDirection.up,
      totalWorkoutDuration: 180,
      newPRs: const [],
      currentStreak: 5,
      bestDay: bestDay,
      healthScore: 72,
      topInsights: const [],
      suggestions: const ['Keep logging'],
    );
  }

  Future<void> pumpReport(
    WidgetTester tester, {
    DateTime? bestDay,
    int workoutCount = 3,
  }) async {
    when(() => service.generateReport(any())).thenAnswer(
      (invocation) async => reportFor(
        invocation.positionalArguments.first as DateTime,
        bestDay: bestDay,
        workoutCount: workoutCount,
      ),
    );

    await pumpScreen(
      tester,
      const WeeklyReportScreen(),
      overrides: [weeklyReportServiceProvider.overrideWithValue(service)],
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the report figures rather than zeros', (tester) async {
    await pumpReport(tester);

    // 80% compliance and 3 workouts come from the report. Both cards used to
    // read keys the payload never carried and fall back to 0.
    expect(find.text('80%'), findsOneWidget);
    expect(find.text('3'), findsWidgets);
    expect(find.text('0%'), findsNothing);
  });

  testWidgets('the week selector regenerates for the week it selects', (
    tester,
  ) async {
    await pumpReport(tester);

    final firstRequest =
        verify(() => service.generateReport(captureAny())).captured.last
            as DateTime;

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    final secondRequest =
        verify(() => service.generateReport(captureAny())).captured.last
            as DateTime;

    // The label used to move while the provider kept producing the current
    // week, so the screen showed last week's dates over this week's numbers.
    expect(firstRequest.difference(secondRequest).inDays, 7);
  });

  testWidgets('shows no best day when the report has none', (tester) async {
    await pumpReport(tester);

    // "Best Day: Wednesday" was hardcoded here and survived every real report.
    expect(find.textContaining('Wednesday'), findsNothing);
    expect(find.textContaining('Best Day'), findsNothing);
  });

  testWidgets('shows the report\'s own best day when it has one', (
    tester,
  ) async {
    // A Thursday, so a leftover hardcoded weekday would still be visible.
    await pumpReport(tester, bestDay: DateTime(2026, 8, 27));

    expect(find.textContaining('Thursday'), findsOneWidget);
  });

  testWidgets('surfaces a generation failure instead of an empty report', (
    tester,
  ) async {
    when(
      () => service.generateReport(any()),
    ).thenThrow(StateError('no data for that week'));

    await pumpScreen(
      tester,
      const WeeklyReportScreen(),
      overrides: [weeklyReportServiceProvider.overrideWithValue(service)],
    );
    await tester.pumpAndSettle();

    expect(find.text('80%'), findsNothing);
    expect(find.textContaining('no data for that week'), findsOneWidget);
  });
}
