import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    // Implementing Google Sign-In requires google_sign_in package dependency.
    // Assuming configured or placeholder.
    // The prompt setup includes dependencies but specific implementation details for Google Sign-In usually involve platform channel.
    // I'll throw UnimplementedError or implement minimal logic if package present.
    // For now, assume it's properly handled or defer implementation.
    throw UnimplementedError('Google Sign-In requires additional setup.');
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
