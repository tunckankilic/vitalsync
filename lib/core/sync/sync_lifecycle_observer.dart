/// VitalSync — Sync Lifecycle Observer.
///
/// Flushes the pending sync queue one last time when the app moves to the
/// background ([AppLifecycleState.paused]). iOS grants a short execution
/// window on backgrounding, which is usually enough for the small HTTP push.
/// Deliberately does NOT use BGTaskScheduler / UIBackgroundModes — background
/// execution is opportunistic and is not part of the critical path.
library;

import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter/widgets.dart';

import 'sync_service.dart';

/// Triggers a final sync flush when the app is backgrounded.
///
/// Registered via [WidgetsBinding.addObserver] at startup and kept for the
/// app's lifetime. All sync preconditions (auth, connectivity, GDPR consent,
/// reentrancy) are enforced inside [SyncService.sync]; this observer only
/// adds the lifecycle trigger, plus a cheap [SyncService.isSyncing] check to
/// avoid kicking off a redundant attempt while a sync is already running
/// (mirroring [SyncService.startAutoSync]).
class SyncLifecycleObserver with WidgetsBindingObserver {
  SyncLifecycleObserver({required SyncService syncService})
    : _syncService = syncService;

  final SyncService _syncService;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.paused) return;

    if (_syncService.isSyncing) {
      log('App paused — sync already in progress, skipping flush');
      return;
    }

    log('App paused — flushing pending sync queue');
    // Fire-and-forget: sync has its own retry/queue handling; a failure here
    // is retried by auto-sync or on the next foreground session.
    unawaited(
      _syncService.sync().catchError((Object error) {
        log('Background flush sync failed: $error');
      }),
    );
  }
}
