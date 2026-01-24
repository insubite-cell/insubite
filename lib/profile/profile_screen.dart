import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:insubite/design_system/inputs/app_text_field.dart';
import 'package:insubite/design_system/theme/app_input_decoration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../design_system/buttons/app_button.dart';
import '../main.dart';



class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _edadController = TextEditingController();

  String _generoSeleccionado = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosPerfil();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _edadController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosPerfil() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .collection('Dato usuario')
        .doc('info')
        .get();

    final data = doc.data();

    if (data != null) {
      // 🔹 Datos ya guardados manualmente
      _nombreController.text = data['nombre'] ?? '';
      _apellidoController.text = data['apellido'] ?? '';
      _edadController.text = data['edad']?.toString() ?? '';
      _generoSeleccionado = data['genero'] ?? '';
    } else {
      // 🔹 Usuario nuevo / login con Google
      final displayName = user.displayName ?? '';
      if (displayName.isNotEmpty) {
        final parts = displayName.split(' ');
        _nombreController.text = parts.first;
        _apellidoController.text =
            parts.length > 1 ? parts.sublist(1).join(' ') : '';
      }
    }
  }

  setState(() => _loading = false);
}


  Future<void> _guardarDatosPerfil() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('Dato usuario')
          .doc('info')
          .set({
        'nombre': _nombreController.text.trim(),
        'apellido': _apellidoController.text.trim(),
        'edad': int.tryParse(_edadController.text.trim()) ?? 0,
        'genero': _generoSeleccionado,
        'email': user.email,
      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos guardados')),
      );
    }

    setState(() => _loading = false);
  }

  Future<void> _cambiarTema(bool valor) async {
    temaNotifier.value = valor;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tema_oscuro', valor);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return AppTextField(
    controller: controller,
    label: label,
    keyboardType: keyboardType,
    validator: validator,
  );

  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Perfil',
          style: TextStyle(fontSize: 18.sp),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isTablet = constraints.maxWidth > 600;
                final fieldWidth = isTablet ? 420.w : double.infinity;
                final spacing = 16.h;

                return SingleChildScrollView(
                  padding: EdgeInsets.all(spacing),
                  child: Form(
                    key: _formKey,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isTablet ? 600.w : double.infinity,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              email,
                              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                            ),

                            SizedBox(height: spacing),

                            SizedBox(
                              width: fieldWidth,
                              child: _buildTextField(
                                controller: _nombreController,
                                label: 'Nombre',
                                validator: (v) =>
                                    v == null || v.isEmpty ? 'Ingrese un nombre' : null,
                              ),
                            ),

                            SizedBox(height: spacing),

                            SizedBox(
                              width: fieldWidth,
                              child: _buildTextField(
                                controller: _apellidoController,
                                label: 'Apellido',
                                validator: (v) =>
                                    v == null || v.isEmpty ? 'Ingrese un apellido' : null,
                              ),
                            ),

                            SizedBox(height: spacing),

                            SizedBox(
                              width: fieldWidth,
                              child: _buildTextField(
                                controller: _edadController,
                                label: 'Edad',
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Ingrese su edad';
                                  final n = int.tryParse(v);
                                  if (n == null || n <= 0) return 'Edad inválida';
                                  return null;
                                },
                              ),
                            ),

                            SizedBox(height: spacing),

                           SizedBox(
                                  width: fieldWidth,
                                  child: DropdownButtonFormField<String>(
                                    initialValue:
                                        _generoSeleccionado.isNotEmpty ? _generoSeleccionado : null,
                                    items: const [
                                      DropdownMenuItem(value: 'Masculino', child: Text('Masculino')),
                                      DropdownMenuItem(value: 'Femenino', child: Text('Femenino')),
                                      DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                                    ],
                                    onChanged: (v) => setState(() => _generoSeleccionado = v ?? ''),
                                    validator: (v) =>
                                        v == null || v.isEmpty ? 'Seleccione un género' : null,
                                    decoration: appInputDecoration(label: 'Género'),
                                  ),
                                ),



                            SizedBox(height: spacing * 1.5),

                            /// 🔹 BOTÓN GUARDAR (estandarizado)
                            SizedBox(
                              width: fieldWidth,
                              child: AppButton(
                                label: 'Guardar',
                                expanded: true,
                                loading: _loading,
                                onPressed: _guardarDatosPerfil,
                              ),
                            ),

                            SizedBox(height: spacing),

                            /// 🔹 BOTÓN DATOS MÉDICOS
                            SizedBox(
                              width: fieldWidth,
                              child: AppButton(
                                label: 'Ir a Datos Médicos',
                                expanded: true,
                                outlined: true,
                                onPressed: () =>
                                    Navigator.pushNamed(context, '/medical'),
                              ),
                            ),

                            SizedBox(height: spacing * 1.5),

                            /// 🔹 TEMA
                            ValueListenableBuilder<bool>(
                              valueListenable: temaNotifier,
                              builder: (context, isDark, _) {
                                return SwitchListTile(
                                  title: Text(
                                    'Modo Oscuro',
                                    style: TextStyle(fontSize: 14.sp),
                                  ),
                                  value: isDark,
                                  onChanged: _cambiarTema,
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
