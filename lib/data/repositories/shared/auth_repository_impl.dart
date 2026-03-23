import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:vitalsync/domain/models/app_auth_result.dart';
import 'package:vitalsync/domain/models/app_user.dart';
import 'package:vitalsync/domain/repositories/shared/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  }) : _auth = auth,
       _firestore = firestore;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// Converts a Firebase [User] to domain [AppUser].
  static AppUser? _toAppUser(User? user) {
    if (user == null) return null;
    return AppUser(
      id: user.uid,
      email: user.email,
      displayName: user.displayName,
      emailVerified: user.emailVerified,
      photoUrl: user.photoURL,
      createdAt: user.metadata.creationTime,
      lastSignInAt: user.metadata.lastSignInTime,
    );
  }

  @override
  Stream<AppUser?> get authStateChanges =>
      _auth.authStateChanges().map(_toAppUser);

  @override
  AppUser? get currentUser => _toAppUser(_auth.currentUser);

  @override
  Future<AppAuthResult> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return AppAuthResult(
      user: _toAppUser(credential.user)!,
      isNewUser: credential.additionalUserInfo?.isNewUser ?? false,
    );
  }

  @override
  Future<AppAuthResult> signUp(
    String email,
    String password,
    String name,
  ) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final appUser = _toAppUser(credential.user)!;
    await createInitialProfile(appUser, name);
    return AppAuthResult(user: appUser, isNewUser: true);
  }

  @override
  Future<AppAuthResult> signInWithGoogle() {
    // Google Sign-In has been removed in favor of Apple Sign-In
    throw UnimplementedError(
      'Google Sign-In is no longer supported. Use Apple Sign-In instead.',
    );
  }

  @override
  Future<AppAuthResult> signInWithApple() async {
    try {
      // Request Apple ID credentials
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create an OAuthCredential from the Apple ID credential
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in to Firebase with the Apple credential
      final userCredential = await _auth.signInWithCredential(oauthCredential);
      final isNewUser =
          userCredential.additionalUserInfo?.isNewUser ?? false;

      // Create initial profile if this is a new user
      if (isNewUser) {
        final displayName =
            appleCredential.givenName != null &&
                    appleCredential.familyName != null
                ? '${appleCredential.givenName} ${appleCredential.familyName}'
                : userCredential.user?.email?.split('@').first ?? 'User';

        final appUser = _toAppUser(userCredential.user)!;
        await createInitialProfile(appUser, displayName);
      }

      return AppAuthResult(
        user: _toAppUser(userCredential.user)!,
        isNewUser: isNewUser,
      );
    } catch (e) {
      throw Exception('Apple Sign-In failed: $e');
    }
  }

  @override
  Future<void> signOut() {
    return _auth.signOut();
  }

  @override
  Future<void> resetPassword(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> createInitialProfile(AppUser user, String name) async {
    await _firestore.collection('users').doc(user.id).set({
      'name': name,
      'email': user.email,
      'createdAt': FieldValue.serverTimestamp(),
      'role': 'user',
    });
  }

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.delete();
    }
  }
}
