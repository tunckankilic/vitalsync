/// VitalSync — Sync Riverpod Providers.
///
/// connectivityProvider (stream — online/offline)
/// syncStatusProvider (idle/syncing/error)
/// pendingSyncCountProvider
/// syncNotifier (triggerSync, auto-sync on connectivity changes)
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/repositories/shared/sync_repository.dart';
import '../di/injection_container.dart';
import '../network/connectivity_service.dart';
import '../sync/sync_service.dart';

part 'sync_provider.g.dart';

/// Sync status enum
enum SyncStatus { idle, syncing, error }

/// Provider for ConnectivityService instance
@Riverpod(keepAlive: true)
ConnectivityService connectivityService(Ref ref) {
  return getIt<ConnectivityService>();
}

/// Provider for SyncService instance
@Riverpod(keepAlive: true)
SyncService syncService(Ref ref) {
  return getIt<SyncService>();
}

/// Provider for SyncRepository instance
@Riverpod(keepAlive: true)
SyncRepository syncRepository(Ref ref) {
  return getIt<SyncRepository>();
}

/// Stream provider for connectivity status
@riverpod
Stream<bool> connectivity(Ref ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.connectivityStream;
}

/// Provider for sync status
@riverpod
class SyncStatusNotifier extends _$SyncStatusNotifier {
  @override
  SyncStatus build() {
    // Start listening to connectivity changes for auto-sync
    _listenToConnectivity();
    return SyncStatus.idle;
  }

  /// Listen to connectivity changes and trigger auto-sync
  void _listenToConnectivity() {
    ref.listen(connectivityProvider, (previous, next) {
      next.whenData((isConnected) {
        if (isConnected && state == SyncStatus.idle) {
          // Auto-sync when coming online
          triggerSync().catchError((error) {
            // Silently fail for auto-sync
            state = SyncStatus.error;
          });
        }
      });
    });
  }

  /// Trigger a manual sync
  Future<void> triggerSync() async {
    if (state == SyncStatus.syncing) {
      return; // Already syncing
    }

    state = SyncStatus.syncing;

    final syncService = ref.read(syncServiceProvider);

    try {
      await syncService.sync();
      state = SyncStatus.idle;
    } catch (e) {
      state = SyncStatus.error;
      rethrow;
    }
  }

  /// Reset error status
  void resetError() {
    if (state == SyncStatus.error) {
      state = SyncStatus.idle;
    }
  }
}

/// Provider for pending sync count
@riverpod
Future<int> pendingSyncCount(Ref ref) async {
  final repository = ref.watch(syncRepositoryProvider);
  final pendingItems = await repository.getPendingItems();
  return pendingItems.length;
}
