import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtiene todos los cálculos del usuario (actual o uid pasado)
  Future<List<Map<String, dynamic>>> _getCalculations({String? uid}) async {
    final userUid = uid ?? _auth.currentUser?.uid;
    if (userUid == null) return [];
    final snapshot = await _firestore
        .collection("usuarios/$userUid/calculos_carbohidratos")
        .orderBy("fecha", descending: true)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Carbohidratos: Promedio y máximo
  Future<Map<String, double>> getCarbohidratosStats({DateTime? start, DateTime? end, String? uid}) async {
    final docs = await _getCalculations(uid: uid);
    final filtered = _filterByDate(docs, start, end);

    double total = 0;
    double max = 0;
    int count = filtered.length;

    for (var doc in filtered) {
      final carbs = (doc['totalCarbohidratos'] ?? 0).toDouble();
      total += carbs;
      if (carbs > max) max = carbs;
    }

    return {
      "promedio": count > 0 ? total / count : 0,
      "max": max,
    };
  }

  /// Insulina: promedio
  Future<Map<String, double>> getInsulinaStats({DateTime? start, DateTime? end, String? uid}) async {
    final docs = await _getCalculations(uid: uid);
    final filtered = _filterByDate(docs, start, end);

    double totalInsulina = 0;
    double totalCarbs = 0;
    int count = filtered.length;

    for (var doc in filtered) {
      totalInsulina += (doc['insulinaCalculada'] ?? 0).toDouble();
      totalCarbs += (doc['totalCarbohidratos'] ?? 0).toDouble();
    }

    return {
      "insulinaPromedio": count > 0 ? totalInsulina / count : 0,
      "carbsPorUnidad": totalInsulina > 0 ? totalCarbs / totalInsulina : 0,
    };
  }

  /// Distribución por comidas
  Future<Map<String, int>> getComidasStats({DateTime? start, DateTime? end, String? uid}) async {
    final docs = await _getCalculations(uid: uid);
    final filtered = _filterByDate(docs, start, end);

    Map<String, int> distribucion = {
      "Desayuno": 0,
      "Almuerzo": 0,
      "Merienda": 0,
      "Cena": 0,
    };

    for (var doc in filtered) {
      final tipo = doc['tipoComida'];
      if (distribucion.containsKey(tipo)) distribucion[tipo] = distribucion[tipo]! + 1;
    }

    return distribucion;
  }

  /// Nutrientes específicos (promedio)
  Future<Map<String, double>> getNutrientesStats({DateTime? start, DateTime? end, String? uid}) async {
    final docs = await _getCalculations(uid: uid);
    final filtered = _filterByDate(docs, start, end);

    Map<String, double> totals = {};
    int count = filtered.length;

    for (var doc in filtered) {
      final alimentos = doc['alimentos'] as List<dynamic>? ?? [];
      for (var f in alimentos) {
        f.forEach((key, value) {
          if (['nombre','descripcion','imagen','id','porcion'].contains(key)) return;
          totals[key] = (totals[key] ?? 0) + _extractNumber(value);
        });
      }
    }

    if (count > 0) totals.updateAll((k,v) => v/count);
    return totals;
  }

  /// Tendencias
  Future<List<Map<String, dynamic>>> getTendencias({DateTime? start, DateTime? end, String? uid}) async {
    final docs = await _getCalculations(uid: uid);
    final filtered = _filterByDate(docs, start, end);

    // Retorna lista de fecha + carbs + insulina
    return filtered.map((doc) {
      return {
        "fecha": (doc['fecha'] as Timestamp).toDate(),
        "carbohidratos": (doc['totalCarbohidratos'] ?? 0).toDouble(),
        "insulina": (doc['insulinaCalculada'] ?? 0).toDouble(),
      };
    }).toList();
  }

  /// Filtra documentos por fecha
  List<Map<String, dynamic>> _filterByDate(List<Map<String, dynamic>> docs, DateTime? start, DateTime? end){
    return docs.where((doc) {
      final fecha = (doc['fecha'] as Timestamp).toDate();
      if (start != null && fecha.isBefore(start)) return false;
      if (end != null && fecha.isAfter(end)) return false;
      return true;
    }).toList();
  }

  /// Extrae valor numérico de diferentes formatos
  double _extractNumber(dynamic value){
    if(value == null) return 0;
    if(value is num) return value.toDouble();
    if(value is Map && value.containsKey('cantidad')) return (value['cantidad'] as num?)?.toDouble() ?? 0;
    if(value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
