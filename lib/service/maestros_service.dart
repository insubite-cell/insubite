import 'package:cloud_firestore/cloud_firestore.dart';

class MaestrosService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream de alimentos maestro
  Stream<List<Map<String, dynamic>>> alimentos() {
    return _firestore.collection('alimentos_maestro').snapshots().map(
      (snapshot) => snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // opcional: guardar el ID del doc
        return data;
      }).toList(),
    );
  }

  /// Stream de recetas
  Stream<List<Map<String, dynamic>>> recetas() {
    return _firestore.collection('recetas_maestro').snapshots().map(
      (snapshot) => snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList(),
    );
  }

  /// Stream de marcas de sensores
  Stream<List<Map<String, dynamic>>> marcasSensores() {
    return _firestore.collection('marcas_sensores').snapshots().map(
      (snapshot) => snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList(),
    );
  }

  /// Stream de modelos de sensores
  Stream<List<Map<String, dynamic>>> modelosSensores() {
    return _firestore.collection('modelos_sensores').snapshots().map(
      (snapshot) => snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList(),
    );
  }
}
