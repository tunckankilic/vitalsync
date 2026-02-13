/// VitalSync — Insights Module: Insight Engine Provider.
///
/// Riverpod 2.0 provider for InsightEngine with compute/isolate support
/// for heavy processing to prevent UI blocking.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../domain/entities/insights/insight.dart';
import '../../domain/insight_engine.dart';

part 'insight_engine_provider.g.dart';

/// Provider for the InsightEngine instance
@Riverpod(keepAlive: true)
InsightEngine insightEngine(Ref ref) {
  return getIt<InsightEngine>();
}

/// Notifier for triggering insight generation.
///
/// Called on app launch and after workout/medication log completion.
/// The engine internally runs all 10 rules, checks sample sizes,
/// prevents duplicates, and returns newly generated insights.
@riverpod
class GenerateInsightsNotifier extends _$GenerateInsightsNotifier {
  @override
  FutureOr<List<Insight>> build() {
    // No initial generation — caller triggers via generateAll()
    return const [];
  }

  /// Generate all insights by running all 10 engine rules.
  ///
  /// Called on app launch and after workout/medication completion.
  /// Returns the list of newly generated insights.
  Future<List<Insight>> generateAll() async {
    state = const AsyncValue.loading();

    final engine = ref.read(insightEngineProvider);

    try {
      final newInsights = await engine.generateAllInsights();
      state = AsyncValue.data(newInsights);
      return newInsights;
    } on Exception catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return [];
    }
  }
}
