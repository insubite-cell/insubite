import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../design_system/buttons/app_button.dart';
import 'login_form_screen.dart';
import '../secondary_users/secondary_login_screen.dart';

enum TipoUsuario { principal, secundario }

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  TipoUsuario _tipoSeleccionado = TipoUsuario.principal;

  void _handleStart(BuildContext context) {
    if (_tipoSeleccionado == TipoUsuario.principal) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginFormScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SecondaryLoginScreen()),
      );
    }
  }

  Widget _buildSelector(String label, TipoUsuario tipo) {
    final bool isSelected = _tipoSeleccionado == tipo;

    return Expanded(
      child: AppButton(
        label: label,
        outlined: !isSelected,
        onPressed: () {
          setState(() {
            _tipoSeleccionado = tipo;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, _) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 600.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 60.h),

                    Text(
                      '¡Bienvenido a Insubite!',
                      style: TextStyle(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 12.h),

                    Text(
                      'Tu amiguito para el control de la diabetes',
                      style: TextStyle(fontSize: 18.sp),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 56.h),

                    Row(
                      children: [
                        _buildSelector(
                            'Principal', TipoUsuario.principal),
                        SizedBox(width: 12.w),
                        _buildSelector(
                            'Secundario', TipoUsuario.secundario),
                      ],
                    ),

                    SizedBox(height: 40.h),

                    SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        label: 'Comenzar',
                        onPressed: () => _handleStart(context),
                      ),
                    ),

                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
