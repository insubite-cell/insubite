import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '/../design_system/cards/list_nav_card.dart';
import 'dashbord_nutrientes_screen.dart';
import 'static_dashbord_screen.dart';

class DashboardHomeScreen extends StatelessWidget {
  const DashboardHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboards")),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: ListView(
          children: [
            ListNavCard(
              icon: Icons.restaurant,
              title: "Dashboard Carbohidratos",
              subtitle: "Promedio de carbohidratos por comida",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StaticDashbordScreen(),
                  ),
                );
              },
            ),
            SizedBox(height: 12.h),
            ListNavCard(
              icon: Icons.local_drink,
              title: "Dashboard Nutrientes",
              subtitle: "Análisis de sodio, calcio, grasas, etc.",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DashboardNutrientesScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
