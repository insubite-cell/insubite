import 'dart:io';
import 'package:flutter/material.dart';

class FoodPreviewScreen extends StatefulWidget {
  final File image;

  const FoodPreviewScreen({super.key, required this.image});

  @override
  State<FoodPreviewScreen> createState() => _FoodPreviewScreenState();
}

class _FoodPreviewScreenState extends State<FoodPreviewScreen> {
  bool _loading = true;
  List<String> alimentos = [];

  @override
  void initState() {
    super.initState();
    _reconocerAlimentos();
  }

  Future<void> _reconocerAlimentos() async {
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      alimentos = ['Pasta', 'Queso', 'Salsa'];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Análisis del plato')),
      body: Column(
        children: [
          // Imagen principal
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
                          children: alimentos
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
                          'Estadísticas (próximamente)',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 12),
                        _StatRow(label: 'Carbohidratos', value: '— g'),
                        _StatRow(label: 'Proteínas', value: '— g'),
                        _StatRow(label: 'Grasas', value: '— g'),
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
