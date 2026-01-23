import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insubite_new/design_system/inputs/app_text_field.dart';
import 'package:intl/intl.dart';

import '../design_system/inputs/app_dropdown.dart';
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
  String _tipoSeleccionado = 'Tiras de glucosa';

  final List<String> _tiposInsumos = [
    'Tiras de glucosa',
    'Tiras de cetonas',
    'Agujas',
    'Lancetas',
  ];

  bool _loading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _cantidadController.dispose();
    super.dispose();
  }

  /// 🔹 OBTIENE SIEMPRE EL UID DEL USUARIO PRINCIPAL
  Future<String?> _getUidPrincipal() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc =
        await _firestore.collection('usuarios').doc(user.uid).get();

    final data = doc.data();
    if (data == null) return user.uid;

    final principalUid =
        data['lastValidated']?['principalUid']?.toString();

    if (principalUid != null && principalUid.isNotEmpty) {
      return principalUid;
    }

    return user.uid;
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

  /// 🔹 GUARDA SIEMPRE EN EL USUARIO PRINCIPAL
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
        'tipo': _tipoSeleccionado,
        'fecha': DateFormat('yyyy-MM-dd').format(_fechaSeleccionada),
        'cantidad': int.parse(_cantidadController.text),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insumo registrado correctamente')),
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
                      /// 🔹 Dropdown estandarizado
                      AppDropdown<String>(
                        value: _tipoSeleccionado,
                        items: _tiposInsumos,
                        label: 'Tipo de insumo',
                        itemLabel: (e) => e,
                        onChanged: (value) {
                          setState(() => _tipoSeleccionado = value!);
                        },
                      ),

                      SizedBox(height: 12.h),

                      InkWell(
                        onTap: _seleccionarFecha,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Fecha de retiro',
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

                      AppTextField(
                    controller: _cantidadController,
                    label: 'Cantidad retirada',
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Ingrese la cantidad' : null,
                  ),
                      SizedBox(height: 24.h),

                      /// 🔹 BOTÓN ESTANDARIZADO
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
