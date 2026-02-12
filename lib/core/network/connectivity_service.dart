/// VitalSync — Connectivity Service.
///
/// Online/offline detection via connectivity_plus.
/// Provides stream-based connectivity state for sync triggers.
library;

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Connectivity Service for VitalSync.
///
/// Monitors network connectivity status and provides a stream
/// for reactive updates when connectivity changes.
class ConnectivityService {
  ConnectivityService({required Connectivity connectivity})
    : _connectivity = connectivity;
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  final _connectivityController = StreamController<bool>.broadcast();

  /// Stream that emits true when online, false when offline.
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Starts listening to connectivity changes.
  ///
  /// Should be called once during app initialization.
  /// Automatically updates the connectivity stream.
  void startListening() {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final isConnected = _hasConnection(results);
      _connectivityController.add(isConnected);
    });
  }

  /// Stops listening to connectivity changes.
  ///
  /// Should be called when disposing the service.
  Future<void> stopListening() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  /// Checks current connectivity status.
  ///
  /// Returns true if device has internet connectivity, false otherwise.
  Future<bool> isConnected() async {
    final results = await _connectivity.checkConnectivity();
    return _hasConnection(results);
  }

  /// Waits for internet connectivity.
  ///
  /// Returns immediately if already connected.
  /// Otherwise, waits until connectivity is restored.
  Future<void> waitForConnection() async {
    if (await isConnected()) return;

    await connectivityStream.firstWhere((isConnected) => isConnected);
  }

  /// Disposes resources.
  Future<void> dispose() async {
    await stopListening();
    await _connectivityController.close();
  }

  // INTERNAL HELPERS

  /// Determines if connectivity results indicate an active connection.
  bool _hasConnection(List<ConnectivityResult> results) {
    // Check if any result indicates a valid connection
    for (final result in results) {
      switch (result) {
        case ConnectivityResult.mobile:
        case ConnectivityResult.wifi:
        case ConnectivityResult.ethernet:
        case ConnectivityResult.vpn:
          return true;
        case ConnectivityResult.bluetooth:
        case ConnectivityResult.other:
        case ConnectivityResult.none:
          // These don't guarantee internet connectivity
          continue;
      }
    }
    return false;
  }
}
