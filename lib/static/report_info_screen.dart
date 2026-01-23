// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReportesInfoScreen extends StatelessWidget {
  const ReportesInfoScreen({super.key});

  final List<Map<String, dynamic>> reportesInfo = const [
    {
      'titulo': 'Dashboard Carbohidratos',
      'descripcion':
          'Muestra la tendencia de carbohidratos e insulina en el período seleccionado. '
          'Los datos provienen de los cálculos diarios almacenados en Firestore, permitiendo ver cómo varían los consumos a lo largo del tiempo.',
      'icon': Icons.dashboard,
      'color': Colors.blueAccent,
    },
    {
      'titulo': 'Dashboard Nutrientes',
      'descripcion':
          'Distribución de nutrientes consumidos (carbohidratos, fibra, porciones) en el período seleccionado. '
          'Permite identificar qué nutrientes predominan en la dieta.',
      'icon': Icons.food_bank,
      'color': Colors.green,
    },
    {
      'titulo': 'Reporte de Insulina',
      'descripcion':
          'Resumen de insulina aplicada por día, totales y promedios diarios. '
          'Muestra los días con mayor consumo según los registros de Firestore.',
      'icon': Icons.bloodtype,
      'color': Colors.redAccent,
    },
    {
      'titulo': 'Historial de Consumos',
      'descripcion':
          'Resumen de alimentos consumidos, carbohidratos por alimento y dosis de insulina. '
          'Incluye top alimentos por carbohidratos y frecuencia de consumo.',
      'icon': Icons.history,
      'color': Colors.orangeAccent,
    },
    {
      'titulo': 'Reporte de Insumos',
      'descripcion':
          'Muestra el total de insumos retirados por tipo en un rango de fechas seleccionado. '
          'Los datos se cargan automáticamente según la fecha “desde” y “hasta”, y permiten visualizar el consumo de tiras de glucosa, agujas, etc.',
      'icon': Icons.medical_services,
      'color': Colors.green,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explicación de Reportes'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[50],
      body: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: reportesInfo.length,
        itemBuilder: (context, index) {
          final reporte = reportesInfo[index];
          return Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: reporte['color'].withOpacity(0.2),
                  radius: 28.r,
                  child: Icon(
                    reporte['icon'],
                    color: reporte['color'],
                    size: 28.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reporte['titulo'],
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        reporte['descripcion'],
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
