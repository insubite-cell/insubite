import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'food_calculator/info_calculator_screen.dart';
import 'food/food_manager_screen.dart';
import 'food/intro_screen_alimentos.dart';

import '../design_system/cards/list_nav_card.dart';

class DashboardScreenFood extends StatelessWidget {
  const DashboardScreenFood({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dashboard Alimentos',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: ListView(
          children: [
            SizedBox(height: 12.h),

            // ================= Buscar alimentos =================
            ListNavCard(
              icon: Icons.search,
              title: "Buscar alimentos",
              subtitle: "Encuentra y administra tus alimentos",
              onTap: () async {
                final uid = FirebaseAuth.instance.currentUser?.uid;

                if (uid != null) {
                  final doc = await FirebaseFirestore.instance
                      .collection("usuarios")
                      .doc(uid)
                      .collection("intro")
                      .doc("IntroScreenAlimentos")
                      .get();

                  final mostrarIntro = doc.data()?['mostrar'] ?? true;

                  if (!context.mounted) return;

                  if (mostrarIntro) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const IntroScreenAlimentos(),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FoodManagerScreen(),
                      ),
                    );
                  }
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const IntroScreenAlimentos(),
                    ),
                  );
                }
              },
            ),

            SizedBox(height: 20.h),

            // ================= Calcular bolos =================
            ListNavCard(
              icon: Icons.calculate,
              title: "Calcular bolos",
              subtitle: "Accede a la calculadora de insulina",
              onTap: () async {
                final uid = FirebaseAuth.instance.currentUser?.uid;

                if (uid != null) {
                  final doc = await FirebaseFirestore.instance
                      .collection("usuarios")
                      .doc(uid)
                      .collection("intro")
                      .doc("IntroScreenCalculator")
                      .get();

                  final mostrarInfo = doc.data()?['mostrar'] ?? true;

                  if (!context.mounted) return;

                  if (mostrarInfo) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const IntroScreenCalculator(),
                      ),
                    );
                  } else {
                    Navigator.pushNamed(context, '/calculator');
                  }
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const IntroScreenCalculator(),
                    ),
                  );
                }
              },
            ),

            SizedBox(height: 20.h),

            // ================= Favoritos =================
            ListNavCard(
              icon: Icons.favorite,
              title: "Alimentos favoritos",
              subtitle: "Accede a tu lista personalizada",
              onTap: () {
                Navigator.pushNamed(context, '/food_favorite');
              },
            ),
          ],
        ),
      ),
    );
  }
}
