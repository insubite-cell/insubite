import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserSessionService {
  static final UserSessionService _instance =
      UserSessionService._internal();

  factory UserSessionService() => _instance;

  UserSessionService._internal();

  String? _effectiveUid;

  /// UID que debe usarse para TODOS los dashboards
  Future<String> getEffectiveUid() async {
    if (_effectiveUid != null) {
      return _effectiveUid!;
    }

    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    final userDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(currentUid)
        .get();

    final data = userDoc.data();

    _effectiveUid =
        data?['lastValidated']?['principalUid'] ?? currentUid;

    return _effectiveUid!;
  }

  /// Útil si cerrás sesión
  void clear() {
    _effectiveUid = null;
  }
}
