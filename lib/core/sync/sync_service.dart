/// VitalSync — Drift ↔ Firestore Sync Service.
/// Offline-first architecture: Drift is primary, Firestore is backup.
/// Processes sync queue when connectivity is available.
/// Handles conflict resolution via lastModifiedAt timestamps.
library;

import 'dart:developer' show log;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/local/database.dart';
import '../network/connectivity_service.dart';

/// Sync Service for VitalSync.
/// Manages synchronization between local Drift database (primary)
/// and Firestore cloud backup. Uses an offline-first approach where
/// all writes go to Drift first, then sync to Firestore when connected.
class SyncService {
  SyncService({
    required AppDatabase database,
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required ConnectivityService connectivity,
  }) : _database = database,
       _firestore = firestore,
       _auth = auth,
       _connectivity = connectivity;
  final AppDatabase _database;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final ConnectivityService _connectivity;

  bool _isSyncing = false;

  /// Triggers a manual sync operation.
  /// Syncs pending local changes to Firestore and pulls any
  /// remote changes that are newer than local data.
  Future<void> sync() async {
    // Check if already syncing
    if (_isSyncing) {
      log('Sync already in progress, skipping...');
      return;
    }

    // Check connectivity
    if (!await _connectivity.isConnected()) {
      log('No internet connection, sync skipped');
      return;
    }

    // Check authentication
    final user = _auth.currentUser;
    if (user == null) {
      log('User not authenticated, sync skipped');
      return;
    }

    _isSyncing = true;

    try {
      // TODO: Implement full sync logic in Prompt 2.x
      // This is a placeholder implementation
      log('Starting sync for user: ${user.uid}');

      // Step 1: Push pending local changes to Firestore
      await _pushPendingChanges(user.uid);

      // Step 2: Pull remote changes from Firestore
      await _pullRemoteChanges(user.uid);

      log('Sync completed successfully');
    } catch (e) {
      log('Sync failed: $e');
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  /// Pushes pending local changes to Firestore.
  /// Processes the sync queue and uploads modified records.
  Future<void> _pushPendingChanges(String uid) async {
    // TODO: Implement in Prompt 2.x when sync_queue table is available
    // 1. Query sync_queue table for pending items
    // 2. For each pending item:
    //    - Upload to Firestore
    //    - Mark as synced in sync_queue
    //    - Handle conflicts (lastModifiedAt comparison)
    log('Pushing pending changes (placeholder)');
  }

  /// Pulls remote changes from Firestore.
  /// Downloads records that are newer than local copies.
  Future<void> _pullRemoteChanges(String uid) async {
    // TODO: Implement in Prompt 2.x when all tables are available
    // 1. Query Firestore for user's data
    // 2. Compare lastModifiedAt timestamps
    // 3. Update local database with newer records
    // 4. Handle conflicts (server wins by default, or prompt user)
    log('Pulling remote changes (placeholder)');
  }

  /// Performs initial sync when user first signs in.
  /// Downloads all user data from Firestore to local database.
  Future<void> initialSync() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated for initial sync');
    }

    if (!await _connectivity.isConnected()) {
      throw Exception('Internet connection required for initial sync');
    }

    // TODO: Implement initial sync in Prompt 2.x
    // Download all user data collections from Firestore
    log('Initial sync (placeholder) for user: ${user.uid}');
  }

  /// Checks if sync is currently in progress.
  bool get isSyncing => _isSyncing;

  /// Starts automatic sync on connectivity changes.
  /// Listens to connectivity stream and triggers sync when online.
  void startAutoSync() {
    _connectivity.connectivityStream.listen((isConnected) {
      if (isConnected && !_isSyncing) {
        // Trigger sync when coming online
        sync().catchError((error) {
          log('Auto-sync failed: $error');
        });
      }
    });
  }
}
