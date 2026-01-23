
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../design_system/inputs/app_text_field.dart';
import '../design_system/buttons/app_button.dart';
import 'validate_principal_screen.dart';

class RegisterSecondaryScreen extends StatefulWidget {
  const RegisterSecondaryScreen({super.key});

  @override
  State<RegisterSecondaryScreen> createState() =>
      _RegisterSecondaryScreenState();
}

class _RegisterSecondaryScreenState
    extends State<RegisterSecondaryScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController emailController =
      TextEditingController();
  final TextEditingController passwordController =
      TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController nameController =
      TextEditingController();
  final TextEditingController apellidoController =
      TextEditingController();

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

  /* ============================================================
   *  GUARDADO UNIFICADO DE USUARIO SECUNDARIO
   * ============================================================ */
  Future<void> _saveSecondaryUser({
    required User user,
    required String email,
    required String nombre,
    required String apellido,
  }) async {
    final secondaryUid = const Uuid().v4();

    await _firestore.collection('usuarios').doc(user.uid).set({
      'email': email,
      'createdAt': DateTime.now(),
      'isSecondary': true,
      'secondaryUid': secondaryUid,
    }, SetOptions(merge: true));

    await _firestore
        .collection('usuarios')
        .doc(user.uid)
        .collection('Dato usuario')
        .doc('info')
        .set({
      'nombre': nombre,
      'apellido': apellido,
    }, SetOptions(merge: true));
  }

  /* ============================================================
   *  REGISTRO CON EMAIL
   * ============================================================ */
  Future<void> _registerWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user != null) {
        await _saveSecondaryUser(
          user: user,
          email: emailController.text.trim(),
          nombre: nameController.text.trim(),
          apellido: apellidoController.text.trim(),
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Usuario secundario registrado correctamente'),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ValidatePrincipalScreen(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Error desconocido';
      if (e.code == 'email-already-in-use') {
        msg = 'El email ya está en uso';
      }
      if (e.code == 'weak-password') {
        msg = 'La contraseña es muy débil';
      }
      if (e.code == 'invalid-email') {
        msg = 'Email inválido';
      }

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /* ============================================================
   *  REGISTRO CON GOOGLE (CORREGIDO)
   * ============================================================ */
  Future<void> _registerWithGoogle() async {
    setState(() => _loading = true);

    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _loading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _auth.signInWithCredential(credential);

      final user = userCredential.user;
      final isNewUser =
          userCredential.additionalUserInfo?.isNewUser ?? false;

      if (user != null && isNewUser) {
        final displayName = user.displayName ?? '';
        final parts = displayName.split(' ');

        final nombre = nameController.text.trim().isNotEmpty
            ? nameController.text.trim()
            : (parts.isNotEmpty ? parts.first : '');

        final apellido =
            apellidoController.text.trim().isNotEmpty
                ? apellidoController.text.trim()
                : (parts.length > 1
                    ? parts.sublist(1).join(' ')
                    : '');

        await _saveSecondaryUser(
          user: user,
          email: user.email ?? '',
          nombre: nombre,
          apellido: apellido,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Usuario secundario registrado con Google'),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ValidatePrincipalScreen(),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error Google: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /* ============================================================
   *  UI
   * ============================================================ */
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, _) => Scaffold(
        appBar:
            AppBar(title: const Text('Registro Secundario')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: 24.w,
              vertical: 24.h,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _NombreField(controller: nameController),
                  SizedBox(height: 16.h),
                  _ApellidoField(
                      controller: apellidoController),
                  SizedBox(height: 16.h),
                  AppTextField(
                    controller: emailController,
                    label: 'Email',
                    keyboardType:
                        TextInputType.emailAddress,
                    validator: (v) =>
                        v == null || !v.contains('@')
                            ? 'Email inválido'
                            : null,
                  ),
                  SizedBox(height: 16.h),
                  _PasswordField(
                    controller: passwordController,
                    visible: _passwordVisible,
                    onToggle: () => setState(
                        () => _passwordVisible =
                            !_passwordVisible),
                    label: 'Contraseña',
                  ),
                  SizedBox(height: 16.h),
                  _PasswordField(
                    controller:
                        confirmPasswordController,
                    visible: _confirmPasswordVisible,
                    onToggle: () => setState(() =>
                        _confirmPasswordVisible =
                            !_confirmPasswordVisible),
                    label: 'Confirmar Contraseña',
                    validator: (v) =>
                        v != passwordController.text
                            ? 'No coinciden'
                            : null,
                  ),
                  SizedBox(height: 24.h),
                  _loading
                      ? Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: 24.h),
                          child:
                              const CircularProgressIndicator(),
                        )
                      : Column(
                          children: [
                            AppButton(
                              label:
                                  'Registrarse con Email',
                              expanded: true,
                              selected: true,
                              onPressed:
                                  _registerWithEmail,
                            ),
                            SizedBox(height: 12.h),
                            AppButton(
                              label:
                                  'Registrarse con Google',
                              expanded: true,
                              outlined: true,
                              leading:
                                  const Icon(Icons.login),
                              onPressed:
                                  _registerWithGoogle,
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ================== CAMPOS ================== */

class _NombreField extends StatelessWidget {
  final TextEditingController controller;
  const _NombreField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: 'Nombre',
      validator: (v) =>
          v == null || v.isEmpty ? 'Ingrese nombre' : null,
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
      validator: (v) => v == null || v.isEmpty
          ? 'Ingrese apellido'
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
      validator: validator ??
          (v) => v == null || v.length < 6
              ? 'Mínimo 6 caracteres'
              : null,
      suffixIcon: IconButton(
        icon: Icon(
            visible ? Icons.visibility : Icons.visibility_off),
        onPressed: onToggle,
      ),
    );
  }
}
