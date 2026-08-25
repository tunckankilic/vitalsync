/// VitalSync — Health Module: Health Source Providers.
///
/// Exposes the read-only Apple Health connection: whether access is held,
/// when the last import ran, and the three actions the settings screen
/// offers (connect, import now, disconnect).
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/health/health_import_service.dart';

part 'health_source_provider.g.dart';

/// Connection state of the platform health store.
///
/// Counts and timestamps only — no imported value is carried here.
class HealthSourceStatus {
  const HealthSourceStatus({
    required this.isAuthorized,
    required this.lastImportAt,
  });

  final bool isAuthorized;
  final DateTime? lastImportAt;

  @override
  String toString() {
    return 'HealthSourceStatus(isAuthorized: $isAuthorized, '
        'lastImportAt: $lastImportAt)';
  }
}

/// Provider for the HealthImportService instance
@Riverpod(keepAlive: true)
HealthImportService healthImportService(Ref ref) {
  return getIt<HealthImportService>();
}

/// Provider for the current connection state.
///
/// Invalidated by [HealthSourceNotifier] after every action so the settings
/// screen reflects the new state without a manual refresh.
@riverpod
Future<HealthSourceStatus> healthSourceStatus(Ref ref) async {
  final service = ref.watch(healthImportServiceProvider);
  final prefs = getIt<SharedPreferences>();
  final stored = prefs.getString(AppConstants.prefKeyLastHealthImport);

  return HealthSourceStatus(
    isAuthorized: await service.isAuthorized(),
    lastImportAt: stored == null ? null : DateTime.tryParse(stored),
  );
}

/// Notifier for the health source actions.
///
/// Each method rethrows so the screen can surface the failure; the shared
/// state only tracks whether an action is in flight.
@riverpod
class HealthSourceNotifier extends _$HealthSourceNotifier {
  @override
  FutureOr<void> build() {
    // No initial state needed
  }

  /// Requests read access and runs a first import.
  ///
  /// Throws [HealthDataException] when the user declines.
  Future<HealthImportResult> connect() async {
    final service = ref.read(healthImportServiceProvider);
    await service.requestPermissions();
    return _run(service.import);
  }

  /// Runs an import over the window since the last successful run.
  Future<HealthImportResult> importNow() async {
    final service = ref.read(healthImportServiceProvider);
    return _run(service.import);
  }

  /// Releases access and forgets the last-import marker.
  Future<void> disconnect() async {
    final service = ref.read(healthImportServiceProvider);
    await _run(() async {
      await service.disconnect();
      return null;
    });
  }

  /// Runs [action] while holding the loading state, then refreshes the
  /// status provider whatever the outcome — a failed import can still have
  /// moved the authorization state.
  Future<T> _run<T>(Future<T> Function() action) async {
    state = const AsyncValue.loading();

    final result = await AsyncValue.guard(action);
    // Guarded like the other health notifiers: this notifier is autoDispose
    // and the settings screen can be popped while an import is in flight.
    if (ref.mounted) {
      state = result.hasError
          ? AsyncValue.error(result.error!, result.stackTrace!)
          : const AsyncValue.data(null);
      ref.invalidate(healthSourceStatusProvider);
    }

    if (result.hasError) {
      throw result.error!;
    }
    return result.requireValue;
  }
}
