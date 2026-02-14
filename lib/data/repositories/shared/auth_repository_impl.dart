import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:vitalsync/domain/repositories/shared/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  }) : _auth = auth,
       _firestore = firestore;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<UserCredential> signUp(
    String email,
    String password,
    String name,
  ) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (credential.user != null) {
      await createInitialProfile(credential.user!, name);
    }
    return credential;
  }

  @override
  Future<UserCredential> signInWithGoogle() {
    // Google Sign-In has been removed in favor of Apple Sign-In
    throw UnimplementedError('Google Sign-In is no longer supported. Use Apple Sign-In instead.');
  }

  @override
  Future<UserCredential> signInWithApple() async {
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

      // Create initial profile if this is a new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        final displayName = appleCredential.givenName != null && appleCredential.familyName != null
            ? '${appleCredential.givenName} ${appleCredential.familyName}'
            : userCredential.user?.email?.split('@').first ?? 'User';

        if (userCredential.user != null) {
          await createInitialProfile(userCredential.user!, displayName);
        }
      }

      return userCredential;
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
  Future<void> createInitialProfile(User user, String name) async {
    // Create initial user document in Firestore 'users' collection
    // This is distinct from local DB user profile.
    // Usually we sync this down.
    await _firestore.collection('users').doc(user.uid).set({
      'name': name,
      'email': user.email,
      'createdAt': FieldValue.serverTimestamp(),
      'role': 'user',
    });
  }
}
