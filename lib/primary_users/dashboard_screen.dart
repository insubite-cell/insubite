// ignore_for_file: use_build_context_synchronously, deprecated_member_use, unused_import

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:insubite_new/Insumos/insumos_dashboard_screen.dart';
import 'package:insubite_new/design_system/buttons/app_button.dart';
import 'package:insubite_new/sensor_bomba/dahsboard_glde.dart';
import '../group_food/food/food_preview_screen.dart';
import '../design_system/cards/metric_card.dart';
import '../design_system/cards/icon_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required String principalUid});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _cerrarSesion() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/welcome', (_) => false);
  }

  Future<void> _takePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FoodPreviewScreen(image: File(pickedFile.path)),
        ),
      );
    }
  }

  String _sensorStatusText(DateTime caducidad) {
    final diff = caducidad.difference(DateTime.now());
    if (diff.isNegative) return 'Vencido';
    if (diff.inDays == 0) return 'Vence hoy';
    return '${diff.inDays} días';
  }

  /// 🔑 ID DIARIO (LOCAL)
  String get _diarioId {
    final now = DateTime.now();
    final key =
        "${now.year.toString().padLeft(4, '0')}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.day.toString().padLeft(2, '0')}";
    return 'diario_$key';
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Usuario no autenticado')),
      );
    }

    final uid = user.uid;

    return ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'profile') {
                  Navigator.pushNamed(context, '/profile');
                } else if (value == 'medical') {
                  Navigator.pushNamed(context, '/medical');
                } else if (value == 'share') {
                  Navigator.pushNamed(context, '/shared_reports');
                } else if (value == 'logout') {
                  _cerrarSesion();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'profile', child: Text('Mi perfil')),
                PopupMenuItem(value: 'medical', child: Text('Datos médicos')),
                PopupMenuItem(value: 'share', child: Text('Compartir')),
                PopupMenuDivider(),
                PopupMenuItem(value: 'logout', child: Text('Cerrar sesión')),
              ],
            ),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= NOMBRE =================
              StreamBuilder<DocumentSnapshot>(
                stream: _firestore
                    .collection('usuarios')
                    .doc(uid)
                    .collection('Dato usuario')
                    .doc('info')
                    .snapshots(),
                builder: (_, snapshot) {
                  String nombre = 'Usuario';

                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data =
                        snapshot.data!.data() as Map<String, dynamic>;
                    final nombreFirestore =
                        '${data['nombre'] ?? ''} ${data['apellido'] ?? ''}'
                            .trim();
                    if (nombreFirestore.isNotEmpty) {
                      nombre = nombreFirestore;
                    } else if (user.displayName != null &&
                        user.displayName!.isNotEmpty) {
                      // Si no hay datos en Firestore pero sí en Google
                      nombre = user.displayName!;
                    }
                  } else if (user.displayName != null &&
                      user.displayName!.isNotEmpty) {
                    nombre = user.displayName!;
                  }

                  return Text(
                    '¡Hola $nombre!',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),

              SizedBox(height: 16.h),

              // ================= ESTADO DE HOY =================
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estado de hoy',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 12.h),

                      // ✅ MÉTRICAS OPTIMIZADAS (AGREGADO DIARIO)
                      StreamBuilder<DocumentSnapshot>(
                        stream: _firestore
                            .collection('usuarios')
                            .doc(uid)
                            .collection('calculos_agregados')
                            .doc(_diarioId)
                            .snapshots(),
                        builder: (_, snapshot) {
                          double carbs = 0;
                          double insulin = 0;

                          if (snapshot.hasData && snapshot.data!.exists) {
                            final data =
                                snapshot.data!.data() as Map<String, dynamic>;
                            carbs =
                                (data['totalCarbohidratos'] ?? 0).toDouble();
                            insulin =
                                (data['totalInsulina'] ?? 0).toDouble();
                          }

                          return Row(
                            children: [
                              Expanded(
                                child: MetricCard(
                                  label: 'Carbohidratos',
                                  value: '${carbs.toStringAsFixed(1)} g',
                                  color: Colors.orange,
                                  onTap: () =>
                                      _showMetricDialog('Carbohidratos'),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: MetricCard(
                                  label: 'Insulina',
                                  value: '${insulin.toStringAsFixed(1)} U',
                                  color: Colors.lightBlue,
                                  onTap: () =>
                                      _showMetricDialog('Insulina'),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      SizedBox(height: 12.h),

                      // -------- SENSOR --------
                      StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('usuarios')
                            .doc(uid)
                            .collection('sensores')
                            .orderBy('fecha_caducidad')
                            .limit(1)
                            .snapshots(),
                        builder: (_, snapshot) {
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return MetricCard(
                              label: 'Sensor',
                              value: 'Sin sensor activo',
                              color: Colors.grey,
                              onTap: () => Navigator.pushNamed(
                                  context, '/glucose_device'),
                            );
                          }

                          final data = snapshot.data!.docs.first.data()
                              as Map<String, dynamic>;
                          final caducidad =
                              (data['fecha_caducidad'] as Timestamp)
                                  .toDate();

                          return MetricCard(
                            label: 'Sensor',
                            value: _sensorStatusText(caducidad),
                            color: caducidad.isBefore(DateTime.now())
                                ? Colors.red
                                : Colors.green,
                            onTap: () => Navigator.pushNamed(
                                context, '/glucose_device'),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              // ================= GRID =================
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12.w,
                  mainAxisSpacing: 12.h,
                  childAspectRatio: 1.1,
                  children: [
                    IconCard(
                      icon: Icons.food_bank,
                      title: 'Alimentos',
                      subtitle: 'Explora alimentos',
                      onTap: () =>
                          Navigator.pushNamed(context, '/food_explorer'),
                    ),
                   IconCard(
                    icon: Icons.devices,
                    title: 'Dispositivo',
                    subtitle: 'Ver y configurar',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DevicesScreen(),
                        ),
                      );
                    },
                  ),

                    IconCard(
                      icon: Icons.bar_chart,
                      title: 'Reporte',
                      subtitle: 'Historial',
                      onTap: () =>
                          Navigator.pushNamed(context, '/report'),
                    ),
                    IconCard(
                      icon: Icons.receipt_rounded,
                      title: 'Recetas',
                      subtitle: 'Recetas recomendadas',
                      onTap: () =>
                          Navigator.pushNamed(context, '/recipes_explorer'),
                    ),
                    IconCard(
                    icon: Icons.medical_services_outlined,
                    title: 'Insumos',
                    subtitle: 'Gestión de insumos',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const InsumosDashboardScreen(),
                        ),
                      );
                    },
                  ),

                    IconCard(
                      icon: Icons.camera_alt,
                      title: 'Tomar foto',
                      subtitle: 'Agregar foto del plato',
                      onTap: _takePicture,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMetricDialog(String metric) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ir al reporte'),
        content: Text('¿Deseas ver el reporte de $metric?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          AppButton(
            label: 'Sí',
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                metric == 'Carbohidratos'
                    ? '/history_report'
                    : '/insulin_report',
              );
            },
          )
        ],
      ),
    );
  }
}
