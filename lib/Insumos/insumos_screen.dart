import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../design_system/inputs/app_dropdown.dart';
import '../design_system/inputs/app_text_field.dart';
import '../design_system/buttons/app_button.dart';

class InsumosScreen extends StatefulWidget {
  const InsumosScreen({super.key});

  @override
  State<InsumosScreen> createState() => _InsumosScreenState();
}

class _InsumosScreenState extends State<InsumosScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadController = TextEditingController();

  DateTime _fechaSeleccionada = DateTime.now();

  /// 🔹 CLAVES TÉCNICAS
  String _tipoSeleccionado = 'tiras_glucosa';

  final Map<String, String> _tiposInsumos = {
    'tiras_glucosa': 'Tiras de glucosa',
    'tiras_cetonas': 'Tiras de cetonas',
    'agujas': 'Agujas',
    'lancetas': 'Lancetas',
    'insulina_rapida': 'Insulina rápida',
    'insulina_lenta': 'Insulina lenta',
  };

  /// 🔹 Movimiento
  String _movimientoSeleccionado = 'salida';
  final List<String> _tiposMovimiento = ['entrada', 'salida'];

  bool _loading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _cantidadController.dispose();
    super.dispose();
  }

  /// 🔹 UID PRINCIPAL
  Future<String?> _getUidPrincipal() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc =
        await _firestore.collection('usuarios').doc(user.uid).get();

    return doc.data()?['lastValidated']?['principalUid'] ?? user.uid;
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _fechaSeleccionada = picked);
    }
  }

  /// 🔹 GUARDAR INSUMO
  Future<void> _guardarInsumo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final uidPrincipal = await _getUidPrincipal();
      if (uidPrincipal == null) {
        throw Exception('No se pudo obtener UID principal');
      }

      await _firestore
          .collection('usuarios')
          .doc(uidPrincipal)
          .collection('insumos')
          .add({
        'tipo': _tipoSeleccionado, // 👈 clave técnica
        'tipo_normalizado': _tipoSeleccionado,
        'movimiento': _movimientoSeleccionado,
        'fecha': Timestamp.fromDate(_fechaSeleccionada), // fecha real de negocio
        'fecha_str': DateFormat('yyyy-MM-dd').format(_fechaSeleccionada), // display
        'cantidad': int.parse(_cantidadController.text),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Movimiento registrado correctamente'),
        ),
      );

      _cantidadController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, _) => Scaffold(
        appBar: AppBar(
          title: Text(
            'Registro de Insumos',
            style: TextStyle(fontSize: 18.sp),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      /// 🔹 Entrada / Salida
                      AppDropdown<String>(
                        value: _movimientoSeleccionado,
                        items: _tiposMovimiento,
                        label: 'Movimiento',
                        itemLabel: (e) =>
                            e == 'entrada' ? 'Entrada' : 'Salida',
                        onChanged: (value) {
                          setState(() => _movimientoSeleccionado = value!);
                        },
                      ),

                      SizedBox(height: 12.h),

                      /// 🔹 Tipo de insumo
                      AppDropdown<String>(
                        value: _tipoSeleccionado,
                        items: _tiposInsumos.keys.toList(),
                        label: 'Tipo de insumo',
                        itemLabel: (k) => _tiposInsumos[k]!,
                        onChanged: (value) {
                          setState(() => _tipoSeleccionado = value!);
                        },
                      ),

                      SizedBox(height: 12.h),

                      /// 🔹 Fecha
                      InkWell(
                        onTap: _seleccionarFecha,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Fecha',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('dd/MM/yyyy')
                                    .format(_fechaSeleccionada),
                              ),
                              const Icon(Icons.calendar_today),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 12.h),

                      /// 🔹 Cantidad
                      AppTextField(
                        controller: _cantidadController,
                        label: 'Cantidad',
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            v == null || v.isEmpty
                                ? 'Ingrese la cantidad'
                                : null,
                      ),

                      SizedBox(height: 24.h),

                      /// 🔹 Guardar
                      AppButton(
                        label: 'Guardar',
                        onPressed: _guardarInsumo,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
