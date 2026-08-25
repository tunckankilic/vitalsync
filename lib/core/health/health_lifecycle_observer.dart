/// VitalSync — Health Lifecycle Observer.
///
/// Triggers an Apple Health import when the app returns to the foreground.
/// HealthKit background delivery and observer queries are deliberately not
/// used in 2.0 — a foreground pull plus the periodic WorkManager task covers
/// the measurement use case without an extra background entitlement.
library;

import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter/widgets.dart';

import 'health_import_service.dart';

/// Imports new health samples when the app is resumed.
///
/// Registered via [WidgetsBinding.addObserver] at startup and kept for the
/// app's lifetime. Mirrors `SyncLifecycleObserver`: the trigger lives here,
/// every precondition (authorization, import window) lives inside
/// [HealthImportService].
class HealthLifecycleObserver with WidgetsBindingObserver {
  HealthLifecycleObserver({required HealthImportService importService})
    : _importService = importService;

  final HealthImportService _importService;

  /// Shortest gap between two resume-triggered imports.
  /// App switching resumes the app constantly; without this the app would
  /// query HealthKit on every glance at the notification shade.
  static const Duration minimumInterval = Duration(minutes: 15);

  DateTime? _lastAttempt;
  bool _isImporting = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    if (_isImporting) {
      log('App resumed — health import already in progress, skipping');
      return;
    }

    final last = _lastAttempt;
    if (last != null && DateTime.now().difference(last) < minimumInterval) {
      log('App resumed — health import throttled');
      return;
    }

    _lastAttempt = DateTime.now();
    _isImporting = true;

    log('App resumed — importing new health samples');
    // Fire-and-forget: a failed import is retried on the next resume or by
    // the periodic background task. A missing authorization is the common
    // case and must not disturb the user here.
    unawaited(
      _importService
          .import()
          .catchError((Object error) {
            log('Foreground health import failed: $error');
            return const HealthImportResult(
              glucoseImported: 0,
              samplesImported: 0,
              duplicatesSkipped: 0,
            );
          })
          .whenComplete(() => _isImporting = false),
    );
  }
}
