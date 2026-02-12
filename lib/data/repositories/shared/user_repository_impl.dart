/// VitalSync — Shared Repository Implementations.
///
/// Concrete implementations for user and authentication repositories.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vitalsync/core/gdpr/gdpr_manager.dart';

import '../../../data/local/database.dart';
import '../../../domain/repositories/shared/user_repository.dart';

/// Concrete implementation of UserRepository.
///
/// Manages user profile data in both Drift and Firestore.
/// Full implementation in Prompt 2.3.
class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl({
    required AppDatabase database,
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required GDPRManager gdprManager,
  }) : _database = database,
       _firestore = firestore,
       _auth = auth,
       _gdprManager = gdprManager;
  final AppDatabase _database;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final GDPRManager _gdprManager;

  // TODO: Implement all methods in Prompt 2.3
}

/// Concrete implementation of AuthRepository.
///
/// Manages Firebase Authentication operations.
/// Full implementation in Prompt 2.3.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  }) : _auth = auth,
       _firestore = firestore;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // TODO: Implement all methods in Prompt 2.3
}
