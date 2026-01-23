import 'package:cloud_firestore/cloud_firestore.dart';

class CalculosAggregatorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /* ================== KEYS ================== */

  String _dayKey(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}-"
      "${d.month.toString().padLeft(2, '0')}-"
      "${d.day.toString().padLeft(2, '0')}";

  /* ================== PUBLIC API ================== */

  /// Llamar siempre que haya un cálculo nuevo
  Future<void> processCalculation({
    required String principalUid,
    required DateTime date,
    required String mealType,
    required double carbs,
    required double insulin,
    List<Map<String, dynamic>>? alimentos, // <-- nueva lista de alimentos
  }) async {
    await Future.wait([
      _updateDaily(
        principalUid: principalUid,
        date: date,
        mealType: mealType,
        carbs: carbs,
        insulin: insulin,
      ),
      _updateGlobal(
        principalUid: principalUid,
        carbs: carbs,
        insulin: insulin,
      ),
      if (alimentos != null)
        _updateAlimentos(
          principalUid: principalUid,
          date: date,
          mealType: mealType,
          alimentos: alimentos,
        ),
    ]);
  }

  /* ================== DAILY ================== */

  Future<void> _updateDaily({
    required String principalUid,
    required DateTime date,
    required String mealType,
    required double carbs,
    required double insulin,
  }) async {
    final dayId = "diario_${_dayKey(date)}";

    final ref = _firestore
        .collection('usuarios')
        .doc(principalUid)
        .collection('calculos_agregados')
        .doc(dayId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.exists ? snap.data()! : {};

      final totalCarbs =
          (data['totalCarbohidratos'] ?? 0).toDouble() + carbs;
      final totalInsulin =
          (data['totalInsulina'] ?? 0).toDouble() + insulin;
      final cantidad = (data['cantidadCalculos'] ?? 0) + 1;

      final porComida = Map<String, dynamic>.from(data['porComida'] ?? {});

      final mealKey = mealType.toLowerCase();
      final mealData = Map<String, dynamic>.from(
        porComida[mealKey] ?? {
          "carbs": 0.0,
          "insulina": 0.0,
        },
      );

      mealData['carbs'] += carbs;
      mealData['insulina'] += insulin;
      porComida[mealKey] = mealData;

      tx.set(
        ref,
        {
          "fecha": _dayKey(date),
          "tipo": "diario",
          "totalCarbohidratos": totalCarbs,
          "totalInsulina": totalInsulin,
          "cantidadCalculos": cantidad,
          "porComida": porComida,
          "lastUpdate": FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  /* ================== GLOBAL ================== */

  Future<void> _updateGlobal({
    required String principalUid,
    required double carbs,
    required double insulin,
  }) async {
    final ref = _firestore
        .collection('usuarios')
        .doc(principalUid)
        .collection('calculos_agregados')
        .doc('global');

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.exists ? snap.data()! : {};

      tx.set(
        ref,
        {
          "tipo": "global",
          "totalCarbohidratos":
              (data['totalCarbohidratos'] ?? 0).toDouble() + carbs,
          "totalInsulina":
              (data['totalInsulina'] ?? 0).toDouble() + insulin,
          "cantidadCalculos":
              (data['cantidadCalculos'] ?? 0) + 1,
          "lastUpdate": FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  /* ================== ALIMENTOS ================== */

  /// Guarda los alimentos consumidos para reportes de top alimentos
  Future<void> _updateAlimentos({
    required String principalUid,
    required DateTime date,
    required String mealType,
    required List<Map<String, dynamic>> alimentos,
  }) async {
    final dayId = "diario_${_dayKey(date)}";
    final ref = _firestore
        .collection('usuarios')
        .doc(principalUid)
        .collection('alimentos')
        .doc(dayId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.exists ? snap.data()! : {};

      final porComida = Map<String, dynamic>.from(data['porComida'] ?? {});
      final mealKey = mealType.toLowerCase();

      final currentList =
          List<Map<String, dynamic>>.from(porComida[mealKey] ?? []);
      currentList.addAll(alimentos);

      porComida[mealKey] = currentList;

      tx.set(
        ref,
        {
          "fecha": _dayKey(date),
          "tipo": "diario",
          "porComida": porComida,
          "lastUpdate": FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }
}
