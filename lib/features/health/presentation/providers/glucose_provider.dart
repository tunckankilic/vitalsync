/// VitalSync — Health Module: Glucose Providers.
///
/// Riverpod providers over [GlucoseRepository]. They read and expose
/// measurements; none of them derives, rates or interprets a value.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../domain/entities/health/glucose_reading.dart';
import '../../../../domain/repositories/health/glucose_repository.dart';

part 'glucose_provider.g.dart';

/// Provider for the GlucoseRepository instance
@Riverpod(keepAlive: true)
GlucoseRepository glucoseRepository(Ref ref) {
  return getIt<GlucoseRepository>();
}

/// Stream provider for the most recent readings
@riverpod
Stream<List<GlucoseReading>> glucoseReadings(Ref ref, {int limit = 50}) {
  final repository = ref.watch(glucoseRepositoryProvider);
  return repository.watchRecent(limit: limit);
}

/// Provider for readings in a date range, oldest first.
///
/// The repository returns newest first; the chronological order is
/// established here so the timeline chart can map the list straight onto
/// the X axis without re-sorting on every rebuild.
@riverpod
Future<List<GlucoseReading>> glucoseReadingsInDateRange(
  Ref ref, {
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final repository = ref.watch(glucoseRepositoryProvider);
  final readings = await repository.getByDateRange(startDate, endDate);
  return readings..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
}

/// Notifier for glucose CRUD operations
@riverpod
class GlucoseNotifier extends _$GlucoseNotifier {
  @override
  FutureOr<void> build() {
    // No initial state needed
  }

  /// Add a new reading
  Future<void> addReading(GlucoseReading reading) async {
    state = const AsyncValue.loading();

    final repository = ref.read(glucoseRepositoryProvider);

    final result = await AsyncValue.guard(() async {
      await repository.insert(reading);
    });
    // Guard the state write: this notifier is autoDispose and the add screen
    // pops once the action completes, so an unguarded write throws "Cannot use
    // the Ref ... after it has been disposed".
    if (ref.mounted) state = result;

    if (result.hasError) {
      throw result.error!;
    }
  }

  /// Update an existing reading
  Future<void> updateReading(GlucoseReading reading) async {
    state = const AsyncValue.loading();

    final repository = ref.read(glucoseRepositoryProvider);

    final result = await AsyncValue.guard(() async {
      await repository.update(reading);
    });
    if (ref.mounted) state = result;

    if (result.hasError) {
      throw result.error!;
    }
  }

  /// Delete a reading
  Future<void> deleteReading(int id) async {
    state = const AsyncValue.loading();

    final repository = ref.read(glucoseRepositoryProvider);

    final result = await AsyncValue.guard(() async {
      await repository.delete(id);
    });
    if (ref.mounted) state = result;

    if (result.hasError) {
      throw result.error!;
    }
  }
}
