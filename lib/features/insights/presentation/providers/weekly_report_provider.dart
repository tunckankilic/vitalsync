/// VitalSync — Insights Module: Weekly Report Providers.
///
/// Riverpod 2.0 providers for weekly report management with code generation.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/weekly_report_service.dart';
import 'insight_provider.dart';

part 'weekly_report_provider.g.dart';

/// Provider for the WeeklyReportService instance
@Riverpod(keepAlive: true)
WeeklyReportService weeklyReportService(Ref ref) {
  return getIt<WeeklyReportService>();
}

/// Provider for current week's report
@riverpod
Future<Map<String, dynamic>> weeklyReport(Ref ref) async {
  final service = ref.watch(weeklyReportServiceProvider);
  return service.generateCurrentWeekReport();
}

/// Provider for previous week's report (for comparison)
@riverpod
Future<Map<String, dynamic>?> previousWeekReport(Ref ref) async {
  final service = ref.watch(weeklyReportServiceProvider);
  return service.getPreviousWeekReport();
}

/// Notifier for weekly report operations
@riverpod
class WeeklyReportNotifier extends _$WeeklyReportNotifier {
  @override
  FutureOr<void> build() {
    // No initial state needed
  }

  /// Generate weekly report and fire analytics
  Future<Map<String, dynamic>> generate() async {
    state = const AsyncValue.loading();

    final service = ref.read(weeklyReportServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);

    final result = await AsyncValue.guard(() async {
      final report = await service.generateCurrentWeekReport();

      // Fire analytics event with report metrics
      await analytics.logWeeklyReportViewed(
        complianceRate: report['compliance_rate'] as double?,
        workoutCount: report['workout_count'] as int?,
      );

      return report;
    });

    state = result.when(
      data: (_) => const AsyncValue.data(null),
      error: AsyncValue.error,
      loading: () => const AsyncValue.loading(),
    );

    if (result.hasError) {
      throw result.error!;
    }

    return result.value as Map<String, dynamic>;
  }

  /// Refresh the current week's report
  Future<Map<String, dynamic>> refresh() async {
    state = const AsyncValue.loading();

    final service = ref.read(weeklyReportServiceProvider);

    final result = await AsyncValue.guard(() async {
      // Invalidate the cached provider to force refresh
      ref.invalidate(weeklyReportProvider);

      return service.generateCurrentWeekReport();
    });

    state = result.when(
      data: (_) => const AsyncValue.data(null),
      error: AsyncValue.error,
      loading: () => const AsyncValue.loading(),
    );

    if (result.hasError) {
      throw result.error!;
    }

    return result.value as Map<String, dynamic>;
  }
}
