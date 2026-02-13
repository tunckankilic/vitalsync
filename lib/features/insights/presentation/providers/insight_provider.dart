/// VitalSync — Insights Module: Insight Providers.
///
/// Riverpod 2.0 providers for insight management with code generation.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/enums/insight_category.dart';
import '../../../../domain/entities/insights/insight.dart';
import '../../../../domain/repositories/insights/insight_repository.dart';

part 'insight_provider.g.dart';

/// Provider for the InsightRepository instance
@Riverpod(keepAlive: true)
InsightRepository insightRepository(Ref ref) {
  return getIt<InsightRepository>();
}

/// Provider for the AnalyticsService instance
@Riverpod(keepAlive: true)
AnalyticsService analyticsService(Ref ref) {
  return getIt<AnalyticsService>();
}

/// Stream provider for active (non-dismissed) insights
@riverpod
Stream<List<Insight>> activeInsights(Ref ref) {
  final repository = ref.watch(insightRepositoryProvider);
  return repository.watchActive();
}

/// Family provider for insights filtered by category
@riverpod
Future<List<Insight>> insightsByCategory(
  Ref ref,
  InsightCategory category,
) async {
  final repository = ref.watch(insightRepositoryProvider);
  return repository.getByCategory(category);
}

/// Provider for unread insight count (for badge display)
@riverpod
Future<int> unreadInsightCount(Ref ref) async {
  final activeInsights = await ref.watch(activeInsightsProvider.future);
  return activeInsights.where((insight) => !insight.isRead).length;
}

/// Notifier for insight operations
@riverpod
class InsightNotifier extends _$InsightNotifier {
  @override
  FutureOr<void> build() {
    // No initial state needed
  }

  /// Mark an insight as read
  Future<void> markAsRead(int id) async {
    state = const AsyncValue.loading();

    final repository = ref.read(insightRepositoryProvider);
    final analytics = ref.read(analyticsServiceProvider);

    state = await AsyncValue.guard(() async {
      // Get the insight to fire analytics with proper metadata
      final activeInsights = await repository.getActive();
      final insight = activeInsights.firstWhere(
        (i) => i.id == id,
        orElse: () => throw Exception('Insight not found'),
      );

      // Mark as read
      await repository.markAsRead(id);

      // Fire analytics event
      await analytics.logInsightViewed(
        insightType: insight.type.toString(),
        category: insight.category.toString(),
        priority: insight.priority.index,
      );
    });

    if (state.hasError) {
      throw state.error!;
    }
  }

  /// Dismiss an insight
  Future<void> dismiss(int id) async {
    state = const AsyncValue.loading();

    final repository = ref.read(insightRepositoryProvider);
    final analytics = ref.read(analyticsServiceProvider);

    state = await AsyncValue.guard(() async {
      // Get the insight to fire analytics with proper metadata
      final activeInsights = await repository.getActive();
      final insight = activeInsights.firstWhere(
        (i) => i.id == id,
        orElse: () => throw Exception('Insight not found'),
      );

      // Dismiss the insight
      await repository.dismiss(id);

      // Fire analytics event
      await analytics.logInsightDismissed(insightType: insight.type.toString());
    });

    if (state.hasError) {
      throw state.error!;
    }
  }
}
