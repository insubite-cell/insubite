import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'report/reports_home_screen.dart';
import 'dashbord/dashbord_home_screen.dart';
import 'report_info_screen.dart';
import '../design_system/cards/list_nav_card.dart';

class ReportsExplorerScreen extends StatelessWidget {
  const ReportsExplorerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Explorador de Reportes"),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: "Ayuda sobre reportes y dashboards",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ReportesInfoScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: ListView(
          children: [
            SizedBox(height: 12.h),

            // Tarjeta Reportes
            ListNavCard(
              icon: Icons.list_alt,
              title: "Reportes",
              subtitle: "Accede a todos los reportes disponibles",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ReportsHomeScreen(),
                  ),
                );
              },
            ),

            SizedBox(height: 20.h),

            // Tarjeta Dashboard
            ListNavCard(
              icon: Icons.show_chart,
              title: "Dashboard",
              subtitle: "Visualiza tus datos de manera gráfica",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DashboardHomeScreen(),
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
