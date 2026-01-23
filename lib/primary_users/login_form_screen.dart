import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:insubite_new/design_system/inputs/app_text_field.dart';

import '../design_system/buttons/app_button.dart';
import 'register_screen.dart';
import 'login_welcome_screen.dart';
import 'reset_password_screen.dart';

class LoginFormScreen extends StatefulWidget {
  const LoginFormScreen({super.key});

  @override
  State<LoginFormScreen> createState() => _LoginFormScreenState();
}

class _LoginFormScreenState extends State<LoginFormScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /* ================== PRINCIPAL UID ================== */

  Future<void> _setPrincipalUid(String userId) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .get();

    if (!userDoc.exists) {
      await FirebaseFirestore.instance.collection('usuarios').doc(userId).set({
        'principalUid': userId,
        'email': FirebaseAuth.instance.currentUser?.email,
        'isSecondary': false,
      });
    }
  }

  /* ================== LOGIN EMAIL ================== */

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final userId = userCredential.user!.uid;
      await _setPrincipalUid(userId);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginWelcomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Error al iniciar sesión')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /* ================== LOGIN GOOGLE ================== */

  Future<void> _loginWithGoogle() async {
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
          await FirebaseAuth.instance.signInWithCredential(credential);

      final userId = userCredential.user!.uid;
      await _setPrincipalUid(userId);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginWelcomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Error con Google Sign-In')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /* ================== UI ================== */

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, _) => Scaffold(
        appBar: AppBar(title: const Text('Iniciar sesión')),
        resizeToAvoidBottomInset: true,
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 24.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 30.h),

                Icon(Icons.login, size: 120.w),

                SizedBox(height: 20.h),

                /* ===== EMAIL ===== */
                AppTextField(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ingrese email' : null,
              ),


                SizedBox(height: 16.h),

                /* ===== PASSWORD ===== */
                AppTextField(
                controller: _passwordController,
                label: 'Contraseña',
                obscureText: true,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ingrese contraseña' : null,
              ),


                SizedBox(height: 28.h),

                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          /* ===== LOGIN ===== */
                          AppButton(
                            label: 'Iniciar sesión',
                            expanded: true,
                            onPressed: _login,
                          ),

                          SizedBox(height: 16.h),

                          /* ===== RESET PASSWORD ===== */
                          AppButton(
                            label: 'Restablecer contraseña',
                            expanded: true,
                            outlined: true,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const ResetPasswordScreen(),
                                ),
                              );
                            },
                          ),

                          SizedBox(height: 16.h),

                          /* ===== GOOGLE ===== */
                          AppButton(
                            label: 'Iniciar sesión con Google',
                            expanded: true,
                            outlined: true,
                            leading: const Icon(Icons.login),
                            onPressed: _loginWithGoogle,
                          ),

                          SizedBox(height: 16.h),

                          /* ===== REGISTER ===== */
                          AppButton(
                            label: 'Registrarse',
                            expanded: true,
                            outlined: true,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
