import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late final GoogleSignIn _googleSignIn;

  AuthService() {
    if (kIsWeb) {
      // Flutter Web necesita clientId de OAuth web
      _googleSignIn = GoogleSignIn(
        clientId:
            '881766632299-g7o1cv9icee6smkuhacm4haknevlj40n.apps.googleusercontent.com',
        scopes: ['email'],
      );
    } else {
      // Android / iOS usan configuración automática de Firebase
      _googleSignIn = GoogleSignIn(
        scopes: ['email'],
      );
    }
  }

  /* ==========================================
   * Actualiza último acceso + datos del usuario
   * ========================================== */
  Future<void> _updateLastAccess(User user) async {
    final displayName = user.displayName ?? '';
    final parts = displayName.split(' ');

    await _firestore.collection('usuarios').doc(user.uid).set({
      'lastAccess': FieldValue.serverTimestamp(),
      'email': user.email,
      'displayName': displayName,
      'firstName': parts.isNotEmpty ? parts.first : null,
      'lastName': parts.length > 1 ? parts.sublist(1).join(' ') : null,
      'photoUrl': user.photoURL,
      'provider': user.providerData.isNotEmpty
          ? user.providerData.first.providerId
          : null,
    }, SetOptions(merge: true));
  }

  /* ===============================
   * LOGIN GOOGLE
   * =============================== */
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      final user = userCredential.user;
      if (user != null) {
        await _updateLastAccess(user);
      }

      return user;
    } catch (e) {
      print("Error login con Google: $e");
      return null;
    }
  }

  /* ===============================
   * LOGIN EMAIL
   * =============================== */
  Future<User?> signInWithEmail(String email, String password) async {
    final UserCredential userCredential =
        await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;
    if (user != null) {
      await _updateLastAccess(user);
    }

    return user;
  }

  /* ===============================
   * Sesión activa (app abierta)
   * =============================== */
  Future<void> updateLastAccessIfLogged() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _updateLastAccess(user);
    }
  }

  /* ===============================
   * Logout
   * =============================== */
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }
}
