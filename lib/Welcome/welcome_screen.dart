import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insubite_new/service/auth_service.dart';

import '../primary_users/login_form_screen.dart';
import '../secondary_users/secondary_login_screen.dart';
import '../design_system/buttons/app_button.dart';


enum TipoUsuario { principal, secundario }

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  TipoUsuario _tipoSeleccionado = TipoUsuario.principal;

  @override
  void initState() {
    super.initState();
    // Actualiza lastAccess si hay sesión activa
    AuthService().updateLastAccessIfLogged();
  }

  void _handleStart(BuildContext context) {
    if (_tipoSeleccionado == TipoUsuario.principal) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginFormScreen(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const SecondaryLoginScreen(),
        ),
      );
    }
  }

  Widget _buildSelector(String label, TipoUsuario tipo) {
    return Expanded(
      child: AppButton(
        label: label,
        selected: _tipoSeleccionado == tipo,
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
      builder: (context, child) {
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 600.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 50.h),
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
                      SizedBox(height: 60.h),

                      Row(
                        children: [
                          _buildSelector(
                            "Principal",
                            TipoUsuario.principal,
                          ),
                          SizedBox(width: 12.w),
                          _buildSelector(
                            "Secundario",
                            TipoUsuario.secundario,
                          ),
                        ],
                      ),

                      SizedBox(height: 40.h),

                      AppButton(
                        label: "Comenzar",
                        expanded: true,
                        selected: true,
                        onPressed: () => _handleStart(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
