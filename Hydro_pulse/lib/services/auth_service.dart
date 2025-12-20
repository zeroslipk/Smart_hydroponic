import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton instance
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  // Auth State Stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current User
  User? get currentUser => _auth.currentUser;

  // Sign Up
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Create user in Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint(
        "AuthService: User created. UID: ${result.user!.uid}. Starting background Firestore write...",
      );

      // Create user document in Firestore (Fire-and-forget, do not await)
      if (result.user != null) {
        _firestore
            .collection('users')
            .doc(result.user!.uid)
            .set({
              'uid': result.user!.uid,
              'email': email,
              'name': name,
              'createdAt': FieldValue.serverTimestamp(),
              'lastLogin': FieldValue.serverTimestamp(),
            })
            .then((_) => debugPrint("AuthService: Firestore write success"))
            .catchError(
              (e) => debugPrint("AuthService: Firestore write failed: $e"),
            );

        // Update display name (best effort, don't block)
        result.user!
            .updateDisplayName(name)
            .catchError(
              (e) => debugPrint("AuthService: Name update failed: $e"),
            );
      }

      debugPrint("AuthService: Returning result immediately.");
      return result;
    } catch (e) {
      debugPrint("AuthService: SignUp Error: $e");
      rethrow;
    }
  }

  // Sign In
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint("AuthService: Starting signIn...");
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint("AuthService: Signed in. UID: ${result.user!.uid}");

      // Update last login (Fire-and-forget)
      if (result.user != null) {
        _firestore
            .collection('users')
            .doc(result.user!.uid)
            .update({'lastLogin': FieldValue.serverTimestamp()})
            .then((_) => debugPrint("AuthService: Last login updated"))
            .catchError(
              (e) => debugPrint("AuthService: Last login update failed: $e"),
            );
      }

      return result;
    } catch (e) {
      debugPrint("AuthService: SignIn Error: $e");
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint("AuthService: Password reset email sent to $email");
    } on FirebaseAuthException catch (e) {
      debugPrint("AuthService: Password reset error code: ${e.code}");
      debugPrint("AuthService: Password reset error message: ${e.message}");
      
      // Provide user-friendly error messages
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email address';
          break;
        case 'invalid-email':
          message = 'Invalid email address format';
          break;
        case 'too-many-requests':
          message = 'Too many requests. Please try again later';
          break;
        default:
          message = e.message ?? 'Failed to send reset email';
      }
      throw Exception(message);
    } catch (e) {
      debugPrint("AuthService: Password reset error: $e");
      rethrow;
    }
  }

  // Delete Account
  Future<void> deleteAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Delete user data from Firestore (Best effort)
        await _firestore
            .collection('users')
            .doc(user.uid)
            .delete()
            .catchError((e) => debugPrint("Error deleting user data: $e"));

        // Delete user from Firebase Auth
        await user.delete();
      }
    } catch (e) {
      debugPrint("Error deleting account: $e");
      rethrow;
    }
  }

  // Get User Data
  Future<DocumentSnapshot> getUserData(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }
}
