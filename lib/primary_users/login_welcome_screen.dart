import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../design_system/buttons/app_button.dart';

class LoginWelcomeScreen extends StatefulWidget {
  const LoginWelcomeScreen({super.key});

  @override
  State<LoginWelcomeScreen> createState() => _LoginWelcomeScreenState();
}

class _LoginWelcomeScreenState extends State<LoginWelcomeScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _precargarDatos();
  }

  Future<void> _precargarDatos() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (!mounted) return;
        setState(() => _loading = false);
        return;
      }

      final firestore = FirebaseFirestore.instance;

      await Future.wait([
        firestore.collection('alimentos_maestro').get(),
        firestore.collection('marcas_sensores').get(),
        firestore.collection('modelos_sensores').get(),
        firestore.collection('recetas_maestro').get(),
      ]);

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      debugPrint('Error al precargar datos: $e');
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
          title: const Text('Bienvenido'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                  vertical: 24.h,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: 24.h),
                        Icon(
                          Icons.favorite,
                          size: 90.w,
                          color: Colors.red,
                        ),
                        SizedBox(height: 24.h),
                        Text(
                          '¡Bienvenido a Insubite!',
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'Tu amiguito para el control de la diabetes',
                          style: TextStyle(
                            fontSize: 16.sp,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child: AppButton(
                            label: 'Continuar',
                            leading: const Icon(Icons.arrow_forward),
                            onPressed: () {
                              Navigator.pushReplacementNamed(
                                context,
                                '/dashboard',
                              );
                            },
                            expanded: true,
                            loading: _loading,
                          ),
                        ),
                        SizedBox(height: 24.h),
                      ],
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
