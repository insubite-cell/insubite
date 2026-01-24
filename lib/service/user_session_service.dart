import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserSessionService {
  // Singleton
  static final UserSessionService _instance = UserSessionService._internal();
  factory UserSessionService() => _instance;
  UserSessionService._internal();

  String? _effectiveUid;

  /// Devuelve el UID que debe usarse para TODOS los dashboards y favoritos
  /// Si el usuario es secundario, devuelve el UID del principal asociado
  Future<String> getEffectiveUid() async {
    // Si ya lo calculamos antes, lo devolvemos
    if (_effectiveUid != null) {
      return _effectiveUid!;
    }

    // UID del usuario actualmente logueado
    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    // Obtenemos su documento en Firestore
    final userDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(currentUid)
        .get();

    final data = userDoc.data();

    // Si es usuario secundario y tiene un principal validado, usamos el UID del principal
    // Si no, usamos el UID del propio usuario (principal)
    _effectiveUid = data?['lastValidated']?['principalUid'] ?? currentUid;

    return _effectiveUid!;
  }

  /// Para limpiar la sesión cuando el usuario cierra sesión
  void clear() {
    _effectiveUid = null;
  }
}
