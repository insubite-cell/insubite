import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insubite/design_system/inputs/app_text_field.dart';

import '../design_system/buttons/app_button.dart';
import 'count_meal_screen.dart';

class MedicalDataScreen extends StatefulWidget {
  const MedicalDataScreen({super.key});

  @override
  State<MedicalDataScreen> createState() => _MedicalDataScreenState();
}

class _MedicalDataScreenState extends State<MedicalDataScreen> {
  final _formKey = GlobalKey<FormState>();

  final _alturaController = TextEditingController();
  final _pesoController = TextEditingController();
  final _insulinaRapidaController = TextEditingController();
  final _insulinaLentaController = TextEditingController();
  final _observacionesController = TextEditingController();

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosMedicos();
  }

  @override
  void dispose() {
    _alturaController.dispose();
    _pesoController.dispose();
    _insulinaRapidaController.dispose();
    _insulinaLentaController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosMedicos() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('datos_medicos')
          .doc('info')
          .get();

      final datos = doc.data();
      if (datos != null) {
        _alturaController.text = datos['altura']?.toString() ?? '';
        _pesoController.text = datos['peso']?.toString() ?? '';
        _insulinaRapidaController.text = datos['insulina_rapida'] ?? '';
        _insulinaLentaController.text = datos['insulina_lenta'] ?? '';
        _observacionesController.text = datos['observaciones'] ?? '';
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _guardarDatosMedicos() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('datos_medicos')
          .doc('info')
          .set({
        'altura': double.tryParse(
                _alturaController.text.trim().replaceAll(',', '.')) ??
            0,
        'peso': double.tryParse(
                _pesoController.text.trim().replaceAll(',', '.')) ??
            0,
        'insulina_rapida': _insulinaRapidaController.text.trim(),
        'insulina_lenta': _insulinaLentaController.text.trim(),
        'observaciones': _observacionesController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    if (!mounted) return;

    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Datos médicos guardados con éxito')),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return AppTextField(
    controller: controller,
    label: label,
    keyboardType: keyboardType,
    validator: validator,
    maxLines: maxLines,
  );

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Datos Médicos',
          style: TextStyle(fontSize: 18.sp),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                final formWidth = isWide ? 520.w : double.infinity;
                final spacing = 16.h;

                return SingleChildScrollView(
                  padding: EdgeInsets.all(spacing),
                  child: Center(
                    child: SizedBox(
                      width: formWidth,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildTextField(
                              controller: _alturaController,
                              label: 'Altura (cm)',
                              keyboardType: TextInputType.number,
                            ),
                            SizedBox(height: spacing),
                            _buildTextField(
                              controller: _pesoController,
                              label: 'Peso (kg)',
                              keyboardType: TextInputType.number,
                            ),
                            SizedBox(height: spacing),
                            _buildTextField(
                              controller: _insulinaRapidaController,
                              label: 'Insulina rápida',
                            ),
                            SizedBox(height: spacing),
                            _buildTextField(
                              controller: _insulinaLentaController,
                              label: 'Insulina lenta',
                            ),
                            SizedBox(height: spacing),
                            _buildTextField(
                              controller: _observacionesController,
                              label: 'Observaciones',
                              maxLines: 3,
                            ),
                            SizedBox(height: spacing * 1.5),

                            /// 🔹 BOTÓN GUARDAR
                            AppButton(
                              label: 'Guardar',
                              expanded: true,
                              loading: _loading,
                              onPressed: _guardarDatosMedicos,
                            ),

                            SizedBox(height: spacing),

                            /// 🔹 BOTÓN INGRESAR RATIO
                            AppButton(
                              label: 'Ingresar Ratio',
                              expanded: true,
                              outlined: true,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ComidasScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
