import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'insulin_report_screen.dart';
import 'history_report_screen.dart';
import 'insumos_report_screen.dart';

import '/../design_system/cards/list_nav_card.dart';

class ReportsHomeScreen extends StatefulWidget {
  const ReportsHomeScreen({super.key});

  @override
  State<ReportsHomeScreen> createState() => _ReportsHomeScreenState();
}

class _ReportsHomeScreenState extends State<ReportsHomeScreen> {
  void _navigateTo(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reportes"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: ListView(
          children: [
            ListNavCard(
              icon: Icons.bloodtype,
              title: "Reporte de Insulina",
              subtitle: "Totales y relación carbohidratos / insulina.",
              onTap: () => _navigateTo(const InsulinReportScreen()),
            ),

            SizedBox(height: 12.h),

            ListNavCard(
              icon: Icons.fastfood,
              title: "Historial de Comidas",
              subtitle:
                  "Distribución por desayuno, almuerzo, cena y merienda.",
              onTap: () => _navigateTo(const HistoryReportScreen()),
            ),

            SizedBox(height: 12.h),

            ListNavCard(
              icon: Icons.medical_services,
              title: "Insumos",
              subtitle: "Consulta el historial de insumos retirados",
              onTap: () =>
                  _navigateTo(const InsumosReportScreenSimple()),
            ),
          ],
        ),
      ),
    );
  }
}
