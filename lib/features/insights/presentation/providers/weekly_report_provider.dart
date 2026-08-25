/// VitalSync — Insights Module: Weekly Report Providers.
///
/// Riverpod 2.0 providers for weekly report management with code generation.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../domain/entities/insights/weekly_report.dart';
import '../../domain/weekly_report_service.dart';
import 'insight_provider.dart';

part 'weekly_report_provider.g.dart';

/// Provider for the WeeklyReportService instance
@Riverpod(keepAlive: true)
WeeklyReportService weeklyReportService(Ref ref) {
  return getIt<WeeklyReportService>();
}

/// Report for the week starting at [weekStart].
///
/// Typed on purpose. This used to hand the UI `toJson()`, whose shape exists
/// for the GDPR export — nested sections, export field names — and every
/// consumer read flat keys that were never in it, so the cards rendered
/// zeros. The entity removes the whole class of mismatch.
///
/// [weekStart] is a parameter so the screen's week selector actually selects
/// a week; it used to always render the current one.
@riverpod
Future<WeeklyReport> weeklyReport(Ref ref, {DateTime? weekStart}) async {
  final service = ref.watch(weeklyReportServiceProvider);
  return service.generateReport(weekStart ?? weekStartOf(DateTime.now()));
}

/// Monday of the week containing [date], at midnight.
DateTime weekStartOf(DateTime date) {
  final midnight = DateTime(date.year, date.month, date.day);
  return midnight.subtract(Duration(days: date.weekday - 1));
}

/// Notifier for weekly report operations
@riverpod
class WeeklyReportActions extends _$WeeklyReportActions {
  @override
  FutureOr<void> build() {
    // No initial state needed
  }

  /// Generate weekly report and fire analytics
  Future<WeeklyReport> generate() async {
    state = const AsyncValue.loading();

    final service = ref.read(weeklyReportServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);

    final result = await AsyncValue.guard(() async {
      final report = await service.generateReport(weekStartOf(DateTime.now()));

      // Fire analytics event with report metrics. These used to be read off
      // the export JSON under names it never carried, so both always went
      // out as null.
      await analytics.logWeeklyReportViewed(
        complianceRate: report.medicationCompliance,
        workoutCount: report.workoutCount,
      );

      return report;
    });

    if (ref.mounted) {
      state = result.when(
        data: (_) => const AsyncValue.data(null),
        error: AsyncValue.error,
        loading: () => const AsyncValue.loading(),
      );
    }

    if (result.hasError) {
      throw result.error!;
    }

    return result.value!;
  }

  /// Refresh the current week's report
  Future<WeeklyReport> refresh() async {
    state = const AsyncValue.loading();

    final service = ref.read(weeklyReportServiceProvider);

    final result = await AsyncValue.guard(() async {
      // Invalidate the cached provider to force refresh
      ref.invalidate(weeklyReportProvider);

      return service.generateReport(weekStartOf(DateTime.now()));
    });

    if (ref.mounted) {
      state = result.when(
        data: (_) => const AsyncValue.data(null),
        error: AsyncValue.error,
        loading: () => const AsyncValue.loading(),
      );
    }

    if (result.hasError) {
      throw result.error!;
    }

    return result.value!;
  }
}
