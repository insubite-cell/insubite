import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '/design_system/buttons/app_button.dart';
import 'food_manager_screen.dart';

class IntroScreenAlimentos extends StatefulWidget {
  const IntroScreenAlimentos({super.key});

  @override
  State<IntroScreenAlimentos> createState() => _IntroScreenAlimentosState();
}

class _IntroScreenAlimentosState extends State<IntroScreenAlimentos> {
  bool _dontShowAgain = false;
  bool _loading = false;

  Future<void> _savePreferenceAndContinue() async {
    setState(() => _loading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance
            .collection("usuarios")
            .doc(uid)
            .collection("intro")
            .doc("IntroScreenAlimentos")
            .set({
          "pantalla": "IntroScreenAlimentos",
          "mostrar": !_dontShowAgain,
        }, SetOptions(merge: true));
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FoodManagerScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar preferencia: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _infoCard(String text) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 16.sp),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, _) => Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 48.h,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Icon(
                        Icons.restaurant_menu,
                        size: 80.sp,
                        color: Colors.green,
                      ),
                    ),

                    SizedBox(height: 20.h),

                    Text(
                      "🍏 Bienvenido a la base de alimentos",
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 16.h),

                    _infoCard(
                      "Aquí encontrarás un catálogo de alimentos con información nutricional básica y orientativa. "
                      "Estos valores provienen de fuentes generales y pueden no coincidir exactamente con tu dieta o producto específico.",
                    ),

                    SizedBox(height: 12.h),

                    _infoCard(
                      "⚠️ Importante:\n"
                      "Si notas que algún alimento no tiene los valores correctos o no coincide con tu necesidad, "
                      "puedes agregarlo a tus favoritos y luego editarlo manualmente para adaptarlo a tu dieta.",
                    ),

                    SizedBox(height: 12.h),

                    _infoCard(
                      "💡 Consejo:\n"
                      "Usa la opción de favoritos ❤️ para guardar los alimentos que más consumas. "
                      "Así podrás acceder rápido y personalizar su información nutricional cuando lo necesites.",
                    ),

                    const Spacer(),

                    Row(
                      children: [
                        Checkbox(
                          value: _dontShowAgain,
                          onChanged: (value) {
                            setState(() => _dontShowAgain = value ?? false);
                          },
                        ),
                        Expanded(
                          child: Text(
                            "No volver a mostrar este aviso",
                            style: TextStyle(fontSize: 16.sp),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16.h),

                    AppButton(
                      label: _loading ? 'Cargando...' : '¡Entendido!',
                      expanded: true,
                      onPressed: _loading ? null : _savePreferenceAndContinue,
                      leading: _loading
                          ? SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
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
