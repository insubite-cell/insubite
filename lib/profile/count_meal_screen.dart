import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insubite/design_system/inputs/app_text_field.dart';

import '../design_system/buttons/app_button.dart';

class ComidasScreen extends StatefulWidget {
  const ComidasScreen({super.key});

  @override
  State<ComidasScreen> createState() => _ComidasScreenState();
}

class _ComidasScreenState extends State<ComidasScreen> {
  final _formKey = GlobalKey<FormState>();

  final _carbDesayunoController = TextEditingController();
  final _insulinaDesayunoController = TextEditingController();

  final _carbAlmuerzoController = TextEditingController();
  final _insulinaAlmuerzoController = TextEditingController();

  final _carbCenaController = TextEditingController();
  final _insulinaCenaController = TextEditingController();

  final _carbMeriendaController = TextEditingController();
  final _insulinaMeriendaController = TextEditingController();

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosComidas();
  }

  @override
  void dispose() {
    _carbDesayunoController.dispose();
    _insulinaDesayunoController.dispose();
    _carbAlmuerzoController.dispose();
    _insulinaAlmuerzoController.dispose();
    _carbCenaController.dispose();
    _insulinaCenaController.dispose();
    _carbMeriendaController.dispose();
    _insulinaMeriendaController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosComidas() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('relacion_comidas')
          .doc('info')
          .get();

      final datos = doc.data();
      if (datos != null) {
        setState(() {
          _carbDesayunoController.text =
              (datos['desayuno_carb']?.toString()) ?? '';
          _insulinaDesayunoController.text =
              (datos['desayuno_insulina']?.toString()) ?? '';

          _carbAlmuerzoController.text =
              (datos['almuerzo_carb']?.toString()) ?? '';
          _insulinaAlmuerzoController.text =
              (datos['almuerzo_insulina']?.toString()) ?? '';

          _carbCenaController.text =
              (datos['cena_carb']?.toString()) ?? '';
          _insulinaCenaController.text =
              (datos['cena_insulina']?.toString()) ?? '';

          _carbMeriendaController.text =
              (datos['merienda_carb']?.toString()) ?? '';
          _insulinaMeriendaController.text =
              (datos['merienda_insulina']?.toString()) ?? '';
        });
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  String? _validateNumber(String? value) {
    if (value == null || value.isEmpty) return 'Campo requerido';
    final n = double.tryParse(value.replaceAll(',', '.'));
    if (n == null || n < 0) return 'Número inválido';
    return null;
  }

  Future<void> _guardarTodo() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    double parseOrZero(TextEditingController c) =>
        double.tryParse(c.text.replaceAll(',', '.')) ?? 0;

    final desayunoCarb = parseOrZero(_carbDesayunoController);
    final desayunoInsulina = parseOrZero(_insulinaDesayunoController);
    final desayunoRatio =
        desayunoCarb > 0 ? desayunoInsulina / desayunoCarb : 0;

    final almuerzoCarb = parseOrZero(_carbAlmuerzoController);
    final almuerzoInsulina = parseOrZero(_insulinaAlmuerzoController);
    final almuerzoRatio =
        almuerzoCarb > 0 ? almuerzoInsulina / almuerzoCarb : 0;

    final cenaCarb = parseOrZero(_carbCenaController);
    final cenaInsulina = parseOrZero(_insulinaCenaController);
    final cenaRatio = cenaCarb > 0 ? cenaInsulina / cenaCarb : 0;

    final meriendaCarb = parseOrZero(_carbMeriendaController);
    final meriendaInsulina = parseOrZero(_insulinaMeriendaController);
    final meriendaRatio =
        meriendaCarb > 0 ? meriendaInsulina / meriendaCarb : 0;

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .collection('relacion_comidas')
        .doc('info')
        .set({
      'desayuno_carb': desayunoCarb,
      'desayuno_insulina': desayunoInsulina,
      'desayuno_ratio': desayunoRatio,
      'almuerzo_carb': almuerzoCarb,
      'almuerzo_insulina': almuerzoInsulina,
      'almuerzo_ratio': almuerzoRatio,
      'cena_carb': cenaCarb,
      'cena_insulina': cenaInsulina,
      'cena_ratio': cenaRatio,
      'merienda_carb': meriendaCarb,
      'merienda_insulina': meriendaInsulina,
      'merienda_ratio': meriendaRatio,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Datos guardados correctamente')),
    );
  }

  Widget _buildComidaFields(
    String comida,
    TextEditingController carbController,
    TextEditingController insulinaController,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          comida.toUpperCase(),
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8.h),
        AppTextField(
        controller: carbController,
        label: 'Carbohidratos (g)',
        keyboardType: TextInputType.number,
        validator: _validateNumber,
      ),

        SizedBox(height: 8.h),
        AppTextField(
        controller: insulinaController,
        label: 'Insulina (U)',
        keyboardType: TextInputType.number,
        validator: _validateNumber,
      ),

        SizedBox(height: 16.h),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Relación Carbohidratos / Insulina'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildComidaFields(
                          'Desayuno',
                          _carbDesayunoController,
                          _insulinaDesayunoController),
                      _buildComidaFields(
                          'Almuerzo',
                          _carbAlmuerzoController,
                          _insulinaAlmuerzoController),
                      _buildComidaFields(
                          'Merienda',
                          _carbMeriendaController,
                          _insulinaMeriendaController),
                      _buildComidaFields(
                          'Cena',
                          _carbCenaController,
                          _insulinaCenaController),

                      SizedBox(height: 24.h),

                      /// BOTÓN ESTANDARIZADO
                      AppButton(
                        label: 'Guardar todo',
                        expanded: true,
                        onPressed: _guardarTodo,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
