import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:insubite/design_system/inputs/app_text_field.dart';
import '../design_system/buttons/app_button.dart';
import 'register_secondary_screen.dart';
import 'validate_principal_screen.dart';
import 'secondary_dashboard_screen.dart';
import 'package:insubite/service/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SecondaryLoginScreen extends StatefulWidget {
  const SecondaryLoginScreen({super.key});

  @override
  State<SecondaryLoginScreen> createState() => _SecondaryLoginScreenState();
}

class _SecondaryLoginScreenState extends State<SecondaryLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = false;
  bool _passwordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /* ================== REDIRECCIÓN ================== */

  Future<void> _redirectAfterLogin(User user) async {
    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      final data = doc.data();
      final principalUid = data?['lastValidated']?['principalUid'] as String?;

      if (!mounted) return;

      if (principalUid != null && principalUid.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SecondaryDashboardScreen(
              principalUid: principalUid,
              principalEmail: data?['lastValidated']?['email'] ?? '',
            ),
          ),
        );
        return;
      }
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ValidatePrincipalScreen()),
    );
  }

  /* ================== LOGIN EMAIL ================== */

  Future<void> _loginWithEmail() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _loading = true);

  final user = await _authService.signInWithEmail(
    _emailController.text.trim(),
    _passwordController.text.trim(),
  );

  if (!mounted) return;

  setState(() => _loading = false);

  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email o contraseña incorrectos'),
      ),
    );
    return;
  }

  await _redirectAfterLogin(user);
}


  /* ================== LOGIN GOOGLE ================== */

  Future<void> _loginWithGoogle() async {
  setState(() => _loading = true);

  final user = await _authService.signInWithGoogle();

  if (!mounted) return;

  setState(() => _loading = false);

  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error al iniciar sesión con Google'),
      ),
    );
    return;
  }

  await _redirectAfterLogin(user);
}


  /* ================== UI ================== */

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, _) => Scaffold(
        appBar: AppBar(title: const Text('Login Secundario')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 40.h),
                  Text(
                    'Inicie sesión con su cuenta secundaria',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16.sp),
                  ),
                  SizedBox(height: 24.h),

                  /* ===== EMAIL ===== */
                  AppTextField(
                    controller: _emailController,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        v == null || !v.contains('@') ? 'Email inválido' : null,
                  ),

                  SizedBox(height: 16.h),

                  /* ===== PASSWORD ===== */
                  AppTextField(
                    controller: _passwordController,
                    label: 'Contraseña',
                    obscureText: !_passwordVisible,
                    validator: (v) =>
                        v == null || v.length < 6
                            ? 'Mínimo 6 caracteres'
                            : null,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _passwordVisible = !_passwordVisible),
                    ),
                  ),

                  SizedBox(height: 28.h),

                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppButton(
                              label: 'Iniciar sesión con Email',
                              expanded: true,
                              onPressed: _loginWithEmail,
                            ),

                            SizedBox(height: 16.h),

                            AppButton(
                              label: 'Iniciar sesión con Google',
                              expanded: true,
                              outlined: true,
                              leading: const Icon(Icons.login),
                              onPressed: _loginWithGoogle,
                            ),

                            SizedBox(height: 24.h),

                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const RegisterSecondaryScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                '¿No tiene cuenta? Registrarse',
                              ),
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
