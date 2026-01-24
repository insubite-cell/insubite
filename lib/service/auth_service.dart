import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:uuid/uuid.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  AuthService();

  /* ============================================================
   *  HELPERS
   * ============================================================ */

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

  /* ============================================================
   *  SIGN IN GOOGLE (NORMAL)
   * ============================================================ */

  Future<User?> signInWithGoogle() async {
    try {
      await _googleSignIn.initialize(
        clientId: kIsWeb
            ? '881766632299-g7o1cv9icee6smkuhacm4haknevlj40n.apps.googleusercontent.com'
            : null,
      );

      final account = await _googleSignIn.authenticate(
        scopeHint: ['email', 'profile'],
      );

      final auth = account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) return null;

      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );

      final userCredential =
          await _auth.signInWithCredential(credential);

      final user = userCredential.user;

      if (user != null) {
        await _updateLastAccess(user);
      }

      return user;
    } catch (e, st) {
      if (kDebugMode) {
        print('Error Google sign-in: $e');
        print(st);
      }
      return null;
    }
  }

  /* ============================================================
   *  REGISTRO SECUNDARIO CON GOOGLE
   * ============================================================ */

  Future<User?> registerSecondaryWithGoogle({
    String? nombre,
    String? apellido,
  }) async {
    try {
      // Init Google (v7)
      await _googleSignIn.initialize(
        clientId: kIsWeb
            ? '881766632299-g7o1cv9icee6smkuhacm4haknevlj40n.apps.googleusercontent.com'
            : null,
      );

      // UI Google
      final account = await _googleSignIn.authenticate(
        scopeHint: ['email', 'profile'],
      );

      final auth = account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) return null;

      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );

      final userCredential =
          await _auth.signInWithCredential(credential);

      final user = userCredential.user;
      final isNewUser =
          userCredential.additionalUserInfo?.isNewUser ?? false;

      if (user != null && isNewUser) {
        await _saveSecondaryUserFromGoogle(
          user: user,
          nombre: nombre,
          apellido: apellido,
        );
      }

      if (user != null) {
        await _updateLastAccess(user);
      }

      return user;
    } catch (e, st) {
      if (kDebugMode) {
        print('AuthService register secondary Google error: $e');
        print(st);
      }
      return null;
    }
  }

  Future<void> _saveSecondaryUserFromGoogle({
    required User user,
    String? nombre,
    String? apellido,
  }) async {
    final secondaryUid = const Uuid().v4();

    final displayName = user.displayName ?? '';
    final parts = displayName.split(' ');

    final finalNombre =
        (nombre != null && nombre.trim().isNotEmpty)
            ? nombre.trim()
            : (parts.isNotEmpty ? parts.first : '');

    final finalApellido =
        (apellido != null && apellido.trim().isNotEmpty)
            ? apellido.trim()
            : (parts.length > 1 ? parts.sublist(1).join(' ') : '');

    await _firestore.collection('usuarios').doc(user.uid).set({
      'email': user.email,
      'createdAt': FieldValue.serverTimestamp(),
      'isSecondary': true,
      'secondaryUid': secondaryUid,
      'provider': 'google',
    }, SetOptions(merge: true));

    await _firestore
        .collection('usuarios')
        .doc(user.uid)
        .collection('Dato usuario')
        .doc('info')
        .set({
      'nombre': finalNombre,
      'apellido': finalApellido,
    }, SetOptions(merge: true));
  }

  /* ============================================================
   *  EMAIL LOGIN
   * ============================================================ */

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        await _updateLastAccess(user);
      }

      return user;
    } catch (e) {
      if (kDebugMode) print('Email login error: $e');
      return null;
    }
  }

  /* ============================================================
   *  MISC
   * ============================================================ */

  Future<void> updateLastAccessIfLogged() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _updateLastAccess(user);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }
}
