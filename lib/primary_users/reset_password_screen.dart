import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insubite_new/design_system/buttons/app_button.dart';
import 'package:insubite_new/design_system/inputs/app_text_field.dart';
import 'login_form_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim().toLowerCase();
    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Correo enviado para restablecer la contraseña'),
        ),
      );

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginFormScreen()),
          );
        }
      });
    } on FirebaseAuthException catch (e) {
      String message = 'Error, intente nuevamente.';
      if (e.code == 'user-not-found') {
        message = 'El correo no está registrado.';
      } else if (e.code == 'invalid-email') {
        message = 'Formato de correo inválido.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Restablecer contraseña'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 520.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 40.h),

                      Icon(
                        Icons.email_outlined,
                        size: 96.w,
                        color: Theme.of(context).colorScheme.primary,
                      ),

                      SizedBox(height: 24.h),

                      Text(
                        'Ingrese su correo electrónico y le enviaremos un enlace para restablecer su contraseña.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15.sp),
                      ),

                      SizedBox(height: 32.h),

                      AppTextField(
                    controller: _emailController,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Ingrese email' : null,
                      ),
                      SizedBox(height: 32.h),

                      _loading
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : SizedBox(
                              width: double.infinity,
                              child: AppButton(
                              label: 'Enviar correo',
                              onPressed: _sendResetEmail,
                            ),

                            ),

                      SizedBox(height: 16.h),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginFormScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Volver al login',
                            style: TextStyle(fontSize: 16.sp),
                          ),
                        ),
                      ),

                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
