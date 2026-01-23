import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:insubite_new/design_system/buttons/app_button.dart';
import 'food_calculator_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class IntroScreenCalculator extends StatefulWidget {
  const IntroScreenCalculator({super.key});

  @override
  State<IntroScreenCalculator> createState() => _IntroScreenCalculator();
}

class _IntroScreenCalculator extends State<IntroScreenCalculator> {
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
            .doc("IntroScreenCalculator")
            .set({
          "pantalla": "IntroScreenCalculator",
          "mostrar": !_dontShowAgain,
        }, SetOptions(merge: true));
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FoodCalculatorScreen()),
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
                      child: Icon(Icons.calculate, size: 80.sp, color: Colors.blue),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      "📝 Configura tu calculadora de bolos",
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Tarjeta informativa 1
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(),
                      ),
                      child: Text(
                        "Esta herramienta te ayudará a estimar de manera automática "
                        "la cantidad de insulina o carbohidratos que podrías necesitar en tus comidas.",
                        style: TextStyle(fontSize: 16.sp),
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Tarjeta informativa 2
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(),
                      ),
                      child: Text(
                        "⚠️ Importante:\nLa calculadora es solo para tu uso personal. "
                        "Debe estar configurada con tus propios parámetros médicos para que los resultados sean correctos.\n\n"
                        "Si no estás seguro de que los datos sean adecuados, consulta siempre con tu médico, tu diabetóloga o un adulto responsable antes de usarla.",
                        style: TextStyle(fontSize: 16.sp),
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Tarjeta informativa 3 con RichText
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(),
                      ),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(fontSize: 16.sp, color: Colors.black),
                          children: [
                            const TextSpan(
                              text: "ℹ️ Cómo funciona:\n"
                                  "Los cálculos se realizan en base a la relación insulina–carbohidratos "
                                  "que tienes registrada en tu perfil dentro de los ",
                            ),
                            TextSpan(
                              text: "datos médicos",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                                fontSize: 16.sp,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.pushNamed(
                                    context,
                                    "/medical",
                                    arguments: {
                                      "highlightFields": [
                                        "carbohidratos_ratio",
                                        "insulina_ratio"
                                      ]
                                    },
                                  );
                                },
                            ),
                            const TextSpan(text: "."),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _dontShowAgain,
                          onChanged: (value) =>
                              setState(() => _dontShowAgain = value ?? false),
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

                    // Botón
                    SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: AppButton(
                      label: "¡Vamos!",
                      onPressed: _savePreferenceAndContinue,
                      loading: _loading,
                      expanded: true, // ocupa todo el ancho
                    ),
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
