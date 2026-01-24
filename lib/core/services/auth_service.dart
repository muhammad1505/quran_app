import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool get isReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Stream<User?> authStateChanges() {
    if (!isReady) {
      return Stream.value(null);
    }
    return FirebaseAuth.instance.authStateChanges();
  }

  User? get currentUser {
    if (!isReady) return null;
    return FirebaseAuth.instance.currentUser;
  }

  Future<UserCredential> signInWithGoogle() async {
    if (!isReady) {
      throw Exception('Firebase belum siap. Pastikan konfigurasi Firebase.');
    }
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Login dibatalkan.');
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    if (!isReady) return;
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Google sign out failed: $e');
    }
    await FirebaseAuth.instance.signOut();
  }
}
