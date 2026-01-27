import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

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

  Future<UserCredential> signInAnonymously() async {
    if (!isReady) {
      throw Exception('Firebase belum siap. Pastikan konfigurasi Firebase.');
    }
    return FirebaseAuth.instance.signInAnonymously();
  }

  Future<void> signOut() async {
    if (!isReady) return;
    await FirebaseAuth.instance.signOut();
  }
}
