// Widget tests for the Dashboard page.
//
// The page reads everything through [dashboardSummaryProvider], so these tests
// override that single provider with a fixed [DashboardSummary] (data state) or
// a never-completing future (loading state) — no GetIt/repository wiring needed.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalsync/core/enums/insight_category.dart';
import 'package:vitalsync/core/enums/insight_priority.dart';
import 'package:vitalsync/core/enums/insight_type.dart';
import 'package:vitalsync/core/enums/medication_frequency.dart';
import 'package:vitalsync/domain/entities/health/medication.dart';
import 'package:vitalsync/domain/entities/insights/insight.dart';
import 'package:vitalsync/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:vitalsync/presentation/pages/dashboard_page.dart';

import '../../support/pump_app.dart';

void main() {
  final medication = Medication(
    id: 1,
    name: 'Aspirin',
    dosage: '100mg',
    frequency: MedicationFrequency.daily,
    times: const ['08:00'],
    startDate: DateTime(2026, 1, 1),
    color: 0xFF2196F3,
    isActive: true,
    lastModifiedAt: DateTime(2026, 1, 1),
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  final insight = Insight(
    id: 1,
    type: InsightType.trend,
    category: InsightCategory.health,
    title: 'Great compliance!',
    message: 'You took all your medications this week.',
    data: const {},
    priority: InsightPriority.medium,
    isRead: false,
    isDismissed: false,
    validUntil: DateTime(2026, 12, 31),
    generatedAt: DateTime(2026, 6, 1),
  );

  final summary = DashboardSummary(
    todayMedications: [medication],
    takenToday: 1,
    totalWorkouts: 42,
    weeklyWorkouts: 3,
    currentStreak: 5,
    healthPercent: 86,
    latestInsight: insight,
  );

  testWidgets('renders real summary data from the provider', (tester) async {
    await pumpScreen(
      tester,
      const DashboardPage(),
      overrides: [
        dashboardSummaryProvider.overrideWith((ref) => summary),
      ],
    );
    await tester.pumpAndSettle();

    // Health score
    expect(find.textContaining('86%'), findsOneWidget);
    // Stats: streak, total workouts, weekly workouts
    expect(find.text('5'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    // Today's medications
    expect(find.text('Aspirin'), findsOneWidget);
    expect(find.text('100mg'), findsOneWidget);
    expect(find.text('1/1 taken'), findsOneWidget);
    // Latest insight
    expect(find.text('Great compliance!'), findsOneWidget);
  });

  testWidgets('shows a spinner while the summary is loading', (tester) async {
    await pumpScreen(
      tester,
      const DashboardPage(),
      overrides: [
        dashboardSummaryProvider.overrideWith(
          (ref) => Completer<DashboardSummary>().future,
        ),
      ],
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
