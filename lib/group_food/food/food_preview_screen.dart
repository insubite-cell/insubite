// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:logger/logger.dart';

import '../food_calculator/calculos_aggregator_service.dart';

class FoodPreviewScreen extends StatefulWidget {
  final File image;

  const FoodPreviewScreen({super.key, required this.image});

  @override
  State<FoodPreviewScreen> createState() => _FoodPreviewScreenState();
}

class _FoodPreviewScreenState extends State<FoodPreviewScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final Logger logger = Logger();

  bool _loading = true;
  bool _saving = false;

  String? _mealType;

  double _carbsPorDosis = 0;
  double _unidadesPorDosis = 0;
  double _userAdjustedInsulin = 0;

  final TextEditingController _insulinController = TextEditingController();
  final Map<String, TextEditingController> _carbControllers = {};

  /// 👉 MISMO MODELO QUE _selectedFoods
  final List<Map<String, dynamic>> _foods = [];

  // ---------------------------------------------------
  // INIT
  // ---------------------------------------------------
  @override
  void initState() {
    super.initState();
    _processImage();
  }

  @override
  void dispose() {
    _insulinController.dispose();
    for (final c in _carbControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------
  // IMAGE → FOOD SUGGESTIONS
  // ---------------------------------------------------
  Future<void> _processImage() async {
    setState(() => _loading = true);

    final user = _auth.currentUser;
    if (user == null) return;

    final detected = await _detectFoods(widget.image);

    for (final name in detected) {
      final food = await _loadFoodData(user.uid, name);
      if (food != null) {
        _addFood(food);
      }
    }

    setState(() => _loading = false);
  }

  Future<List<String>> _detectFoods(File image) async {
    final input = InputImage.fromFile(image);
    final labeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.5),
    );

    final labels = await labeler.processImage(input);
    await labeler.close();

    return labels.map((e) => e.label.toLowerCase()).toSet().toList();
  }

  // ---------------------------------------------------
  // FAVORITOS → MAESTRO
  // ---------------------------------------------------
  Future<Map<String, dynamic>?> _loadFoodData(String uid, String name) async {
    final normalized = name.toLowerCase();

    // 1️⃣ Favoritos
    final fav = await _firestore
        .collection('usuarios')
        .doc(uid)
        .collection('favoritos')
        .where('nombre', isEqualTo: normalized)
        .limit(1)
        .get();

    if (fav.docs.isNotEmpty) {
      return fav.docs.first.data();
    }

    // 2️⃣ Maestro
    final master = await _firestore
        .collection('alimentos_maestro')
        .where('nombre', isEqualTo: normalized)
        .limit(1)
        .get();

    if (master.docs.isNotEmpty) {
      return master.docs.first.data();
    }

    return null;
  }

  // ---------------------------------------------------
  // FOOD MANAGEMENT
  // ---------------------------------------------------
  void _addFood(Map<String, dynamic> food) {
    final id = food['nombre'];

    if (_foods.any((f) => f['id'] == id)) return;

    final carbs =
        (food['carbohidratos']?['cantidad'] ?? 0).toDouble();

    setState(() {
      _foods.add({
        'id': id,
        'nombre': food['nombre'],
        'carbohidratos': {
          'cantidad': carbs,
          'unidad': 'g',
        },
        'proteinas': food['proteinas'],
        'grasas': food['grasas'],
      });

      _carbControllers[id] =
          TextEditingController(text: carbs.toStringAsFixed(1));
    });
  }

  void _removeFood(String id) {
    setState(() {
      _foods.removeWhere((f) => f['id'] == id);
      _carbControllers[id]?.dispose();
      _carbControllers.remove(id);
    });
  }

  double get _totalCarbs {
    double total = 0;
    for (final f in _foods) {
      final id = f['id'];
      total += double.tryParse(_carbControllers[id]?.text ?? '0') ?? 0;
    }
    return total;
  }

  double get _insulinDose {
    if (_carbsPorDosis <= 0 || _unidadesPorDosis <= 0) return 0;
    return (_totalCarbs / _carbsPorDosis) * _unidadesPorDosis;
  }

  // ---------------------------------------------------
  // MEDICAL DATA (MISMO QUE CALCULADORA)
  // ---------------------------------------------------
  Future<void> _loadMedicalData() async {
    final user = _auth.currentUser;
    if (user == null || _mealType == null) return;

    final doc = await _firestore
        .collection('usuarios')
        .doc(user.uid)
        .collection('relacion_comidas')
        .doc('info')
        .get();

    final data = doc.data() ?? {};

    double c = 0;
    double u = 0;

    switch (_mealType!.toLowerCase()) {
      case 'desayuno':
        c = (data['desayuno_carb'] ?? 0).toDouble();
        u = (data['desayuno_insulina'] ?? 0).toDouble();
        break;
      case 'almuerzo':
        c = (data['almuerzo_carb'] ?? 0).toDouble();
        u = (data['almuerzo_insulina'] ?? 0).toDouble();
        break;
      case 'cena':
        c = (data['cena_carb'] ?? 0).toDouble();
        u = (data['cena_insulina'] ?? 0).toDouble();
        break;
      case 'merienda':
        c = (data['merienda_carb'] ?? 0).toDouble();
        u = (data['merienda_insulina'] ?? 0).toDouble();
        break;
    }

    setState(() {
      _carbsPorDosis = c;
      _unidadesPorDosis = u;
      _insulinController.text = _insulinDose.toStringAsFixed(2);
      _userAdjustedInsulin = _insulinDose;
    });
  }

  // ---------------------------------------------------
  // SAVE
  // ---------------------------------------------------
  Future<void> _save() async {
    if (_saving || _mealType == null) return;

    setState(() => _saving = true);

    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('usuarios')
        .doc(user.uid)
        .collection('calculos_carbohidratos')
        .add({
      'fecha': Timestamp.now(),
      'tipoComida': _mealType,
      'alimentos': _foods,
      'totalCarbohidratos': _totalCarbs,
      'insulinaCalculada': _userAdjustedInsulin,
      'origen': 'imagen',
    });

    await CalculosAggregatorService().processCalculation(
      principalUid: user.uid,
      date: DateTime.now(),
      mealType: _mealType!,
      carbs: _totalCarbs,
      insulin: _userAdjustedInsulin,
      alimentos: _foods,
    );

    Navigator.pop(context);
  }

  // ---------------------------------------------------
  // UI
  // ---------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Análisis del plato')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Image.file(widget.image, height: 260, fit: BoxFit.cover),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        hint: const Text('Tipo de comida'),
                        initialValue: _mealType,
                        items: ['Desayuno', 'Almuerzo', 'Cena', 'Merienda']
                            .map((e) =>
                                DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) async {
                          setState(() => _mealType = v);
                          await _loadMedicalData();
                        },
                      ),
                      const SizedBox(height: 12),
                      ..._foods.map((f) {
                        final id = f['id'];
                        return ListTile(
                          title: Text(f['nombre']),
                          subtitle: TextField(
                            controller: _carbControllers[id],
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            decoration:
                                const InputDecoration(labelText: 'Carbohidratos (g)'),
                            onChanged: (_) => setState(() {}),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeFood(id),
                          ),
                        );
                      }),
                      const Divider(),
                      Text('Total carbs: ${_totalCarbs.toStringAsFixed(1)} g'),
                      TextField(
                        controller: _insulinController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration:
                            const InputDecoration(labelText: 'Insulina (U)'),
                        onChanged: (v) {
                          _userAdjustedInsulin =
                              double.tryParse(v.replaceAll(',', '.')) ?? 0;
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _save,
                        child: const Text('Guardar cálculo'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
