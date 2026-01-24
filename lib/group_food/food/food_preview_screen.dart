import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class FoodPreviewScreen extends StatefulWidget {
  final File image;

  const FoodPreviewScreen({super.key, required this.image});

  @override
  State<FoodPreviewScreen> createState() => _FoodPreviewScreenState();
}

class _FoodPreviewScreenState extends State<FoodPreviewScreen> {
  bool _loading = true;
  List<String> alimentosDetectados = [];

  double totalCarbs = 0;
  double totalProtein = 0;
  double totalFat = 0;

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  Map<String, Map<String, double>> favoritos = {};
  Map<String, Map<String, double>> maestro = {};

  @override
  void initState() {
    super.initState();
    _procesarImagen();
  }

  Future<void> _procesarImagen() async {
    setState(() => _loading = true);

    final user = auth.currentUser;
    if (user == null) return;

    final uid = user.uid;

    // 1️⃣ Cargar favoritos y maestro
    favoritos = await _loadFavoritos(uid);
    maestro = await _loadAlimentosMaestro();

    // 2️⃣ Detectar alimentos usando ML Kit
    alimentosDetectados = await _detectarAlimentos(widget.image);

    // 3️⃣ Calcular macros
    _calcularMacros();

    setState(() => _loading = false);
  }

  Future<Map<String, Map<String, double>>> _loadFavoritos(String uid) async {
    final snapshot = await firestore.collection('usuarios/$uid/favoritos').get();
    final Map<String, Map<String, double>> map = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final nombre = data['nombre'] as String?;
      if (nombre != null) {
        map[nombre.toLowerCase()] = {
          'carbs': (data['carbohidratos']?['cantidad'] ?? 0).toDouble(),
          'protein': (data['proteinas']?['cantidad'] ?? 0).toDouble(),
          'fat': (data['grasas']?['cantidad'] ?? 0).toDouble(),
        };
      }
    }
    return map;
  }

  Future<Map<String, Map<String, double>>> _loadAlimentosMaestro() async {
    final snapshot = await firestore.collection('alimentos_maestro').get();
    final Map<String, Map<String, double>> map = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final nombre = data['nombre'] as String?;
      if (nombre != null) {
        map[nombre.toLowerCase()] = {
          'carbs': (data['carbohidratos']?['cantidad'] ?? 0).toDouble(),
          'protein': (data['proteinas']?['cantidad'] ?? 0).toDouble(),
          'fat': (data['grasas']?['cantidad'] ?? 0).toDouble(),
        };
      }
    }
    return map;
  }

  Future<List<String>> _detectarAlimentos(File image) async {
    final inputImage = InputImage.fromFile(image);
    final options = ImageLabelerOptions(confidenceThreshold: 0.5);
    final labeler = ImageLabeler(options: options);

    final List<ImageLabel> labels = await labeler.processImage(inputImage);
    await labeler.close();

    // Devolver solo los nombres detectados
    return labels.map((l) => l.label.toLowerCase()).toList();
  }

  void _calcularMacros() {
    totalCarbs = 0;
    totalProtein = 0;
    totalFat = 0;

    for (var alimento in alimentosDetectados) {
      // primero favoritos, si no está maestro
      final macros = favoritos[alimento] ?? maestro[alimento];
      if (macros != null) {
        totalCarbs += macros['carbs']!;
        totalProtein += macros['protein']!;
        totalFat += macros['fat']!;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Análisis del plato')),
      body: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            child: Image.file(
              widget.image,
              height: 300,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Alimentos detectados',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: alimentosDetectados
                              .map(
                                (a) => Chip(
                                  label: Text(a),
                                  avatar: const Icon(Icons.restaurant),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const Text(
                          'Estadísticas',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        _StatRow(label: 'Carbohidratos', value: '${totalCarbs.toStringAsFixed(1)} g'),
                        _StatRow(label: 'Proteínas', value: '${totalProtein.toStringAsFixed(1)} g'),
                        _StatRow(label: 'Grasas', value: '${totalFat.toStringAsFixed(1)} g'),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
