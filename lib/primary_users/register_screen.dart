import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insubite_new/design_system/buttons/app_button.dart';
import 'package:insubite_new/design_system/inputs/app_text_field.dart';
import 'login_welcome_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController apellidoController = TextEditingController();

  bool _loading = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    apellidoController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final User? user = userCredential.user;

      if (user != null) {
        // Usuario principal
        await _firestore.collection('usuarios').doc(user.uid).set({
          'email': emailController.text.trim(),
          'createdAt': DateTime.now(),
          'isPrincipal': true,
        });

        await _firestore
            .collection('usuarios')
            .doc(user.uid)
            .collection('Dato usuario')
            .doc('info')
            .set({
          'nombre': nameController.text.trim(),
          'apellido': apellidoController.text.trim(),
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario principal registrado correctamente'),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const LoginWelcomeScreen(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg = 'Error desconocido';
      if (e.code == 'email-already-in-use') {
        errorMsg = 'El email ya está siendo utilizado';
      } else if (e.code == 'weak-password') {
        errorMsg = 'La contraseña es inválida (mínimo 6 caracteres)';
      } else if (e.code == 'invalid-email') {
        errorMsg = 'Formato de email inválido';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Registro'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth >= 600;

              return SingleChildScrollView(
                padding:
                    EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 520.w),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: 20.h),

                          // Nombre y Apellido
                          if (isWide)
                            Row(
                              children: [
                                Expanded(
                                  child:
                                      _NombreField(controller: nameController),
                                ),
                                SizedBox(width: 16.w),
                                Expanded(
                                  child: _ApellidoField(
                                      controller: apellidoController),
                                ),
                              ],
                            )
                          else ...[
                            _NombreField(controller: nameController),
                            SizedBox(height: 16.h),
                            _ApellidoField(controller: apellidoController),
                          ],

                          SizedBox(height: 16.h),

                          // Email
                          AppTextField(
                          controller: emailController,
                          label: 'Email',
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) =>
                              value == null || !value.contains('@')
                                  ? 'Email inválido'
                                  : null,
                        ),


                          SizedBox(height: 16.h),

                          // Contraseña y Confirmación
                          if (isWide)
                            Row(
                              children: [
                                Expanded(
                                  child: _PasswordField(
                                    controller: passwordController,
                                    visible: _passwordVisible,
                                    onToggle: () => setState(() =>
                                        _passwordVisible = !_passwordVisible),
                                    label: 'Contraseña',
                                  ),
                                ),
                                SizedBox(width: 16.w),
                                Expanded(
                                  child: _PasswordField(
                                    controller: confirmPasswordController,
                                    visible: _confirmPasswordVisible,
                                    onToggle: () => setState(() =>
                                        _confirmPasswordVisible =
                                            !_confirmPasswordVisible),
                                    label: 'Confirmar contraseña',
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Ingrese la confirmación';
                                      }
                                      if (value !=
                                          passwordController.text) {
                                        return 'Las contraseñas no coinciden';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            _PasswordField(
                              controller: passwordController,
                              visible: _passwordVisible,
                              onToggle: () => setState(() =>
                                  _passwordVisible = !_passwordVisible),
                              label: 'Contraseña',
                            ),
                            SizedBox(height: 16.h),
                            _PasswordField(
                              controller: confirmPasswordController,
                              visible: _confirmPasswordVisible,
                              onToggle: () => setState(() =>
                                  _confirmPasswordVisible =
                                      !_confirmPasswordVisible),
                              label: 'Confirmar contraseña',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ingrese la confirmación';
                                }
                                if (value != passwordController.text) {
                                  return 'Las contraseñas no coinciden';
                                }
                                return null;
                              },
                            ),
                          ],

                          SizedBox(height: 28.h),

                          _loading
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : SizedBox(
                            width: double.infinity,
                            child: AppButton(
                              label: 'Registrarse',
                              onPressed: register,
                            ),
                          ),


                          SizedBox(height: 20.h),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/* ---------- CAMPOS REUTILIZABLES ---------- */

class _NombreField extends StatelessWidget {
  final TextEditingController controller;
  const _NombreField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AppTextField(
              controller: controller,
              label: 'Nombre',
              textCapitalization: TextCapitalization.words,
              validator: (value) =>
                  value == null || value.isEmpty
                      ? 'Ingrese su nombre'
                      : null,
            );

  }
}

class _ApellidoField extends StatelessWidget {
  final TextEditingController controller;
  const _ApellidoField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AppTextField(
    controller: controller,
    label: 'Apellido',
    textCapitalization: TextCapitalization.words,
    validator: (value) =>
        value == null || value.isEmpty
            ? 'Ingrese su apellido'
            : null,
  );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool visible;
  final VoidCallback onToggle;
  final String label;
  final String? Function(String?)? validator;

  const _PasswordField({
    required this.controller,
    required this.visible,
    required this.onToggle,
    required this.label,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
    controller: controller,
    label: label,
    obscureText: !visible,
    suffixIcon: IconButton(
      icon: Icon(
        visible ? Icons.visibility : Icons.visibility_off,
      ),
      onPressed: onToggle,
    ),
    validator: validator ??
        (value) {
          if (value == null || value.length < 6) {
            return 'Mínimo 6 caracteres';
          }
          return null;
        },
  );

  }
}
