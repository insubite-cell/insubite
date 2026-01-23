// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insubite_new/Insumos/insumos_dashboard_screen.dart';
import 'package:insubite_new/design_system/buttons/app_button.dart';
import 'package:insubite_new/sensor_bomba/dahsboard_glde.dart';

// DESIGN SYSTEM
import '/design_system/cards/metric_card.dart';
import '/design_system/cards/icon_card.dart';

class SecondaryDashboardScreen extends StatefulWidget {
  final String principalUid;
  final String principalEmail;

  const SecondaryDashboardScreen({
    super.key,
    required this.principalUid,
    required this.principalEmail,
  });

  @override
  State<SecondaryDashboardScreen> createState() =>
      _SecondaryDashboardScreenState();
}

class _SecondaryDashboardScreenState extends State<SecondaryDashboardScreen>
    with WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool cargando = true;
  String nombrePrincipal = 'Usuario';

  /// 🔹 Flag para forzar reconstrucción de StreamBuilders
  int _refreshFlag = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 🔹 Detecta cuando la app vuelve al foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 🔹 Recarga completa del dashboard al volver de otra pantalla
      _reloadDashboard();
    }
  }

  /// 🔹 Recarga completa del dashboard
  Future<void> _reloadDashboard() async {
    if (!mounted) return;

    setState(() {
      cargando = true; // Muestra loader mientras recarga
    });

    // 🔹 Recarga nombre del principal
    await _cargarNombrePrincipal();

    // 🔹 Fuerza reconstrucción de StreamBuilders y Grid
    if (!mounted) return;
    setState(() {
      _refreshFlag = DateTime.now().millisecondsSinceEpoch;
      cargando = false; // Oculta loader
    });
  }

  /// ✅ Verifica sesión del usuario y carga datos
  Future<void> _checkSession() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } else {
      await _cargarNombrePrincipal();
      if (mounted) setState(() => cargando = false);
    }
  }

  /// 🔹 Carga nombre del principal
  Future<void> _cargarNombrePrincipal() async {
    try {
      final doc = await _firestore
          .collection('usuarios')
          .doc(widget.principalUid)
          .collection('Dato usuario')
          .doc('info')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        nombrePrincipal =
            '${data['nombre'] ?? ''} ${data['apellido'] ?? ''}'.trim();
      }
      if (mounted) setState(() {});
    } catch (_) {
      nombrePrincipal = 'Usuario principal';
      if (mounted) setState(() {});
    }
  }

  /// 🔹 Cierra sesión
  void _cerrarSesion() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/welcome', (_) => false);
  }

  /// 🔹 Estado del sensor
  String _sensorStatusText(DateTime caducidad) {
    final diff = caducidad.difference(DateTime.now());
    if (diff.isNegative) return 'Vencido';
    if (diff.inDays == 0) return 'Vence hoy';
    return '${diff.inDays} días';
  }

  /// 🔹 Diálogo de métricas
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
      ),

        ],
      ),
    );
  }

  /// 🔹 Refresca indicadores manualmente (pull-to-refresh)
  void refreshIndicators() {
    if (!mounted) return;
    setState(() {
      _refreshFlag = DateTime.now().millisecondsSinceEpoch;
    });
  }

  @override
  Widget build(BuildContext context) {
    final DateTime hoyInicio =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final DateTime hoyFin = hoyInicio.add(const Duration(days: 1));

    return ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'logout') _cerrarSesion();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'logout',
                  child: Text('Cerrar sesión'),
                ),
              ],
            ),
          ],
        ),
        body: cargando
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async => refreshIndicators(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ================= NOMBRE =================
                      Text(
                        '¡Hola $nombrePrincipal!',
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // ================= ESTADO DE HOY =================
                      Card(
                        key: ValueKey('estado_hoy_card_$_refreshFlag'),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Estado de hoy',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 12.h),

                              // -------- MÉTRICAS (SOLO HOY) --------
                              StreamBuilder<QuerySnapshot>(
                                key: ValueKey('metric_carbs_$_refreshFlag'),
                                stream: _firestore
                                    .collection(
                                        'usuarios/${widget.principalUid}/calculos_carbohidratos')
                                    .where(
                                      'fecha',
                                      isGreaterThanOrEqualTo:
                                          Timestamp.fromDate(hoyInicio),
                                    )
                                    .where(
                                      'fecha',
                                      isLessThan: Timestamp.fromDate(hoyFin),
                                    )
                                    .snapshots(),
                                builder: (_, snapshot) {
                                  double carbs = 0;
                                  double insulin = 0;

                                  if (snapshot.hasData) {
                                    for (var doc in snapshot.data!.docs) {
                                      carbs +=
                                          (doc['totalCarbohidratos'] ?? 0)
                                              .toDouble();
                                      insulin +=
                                          (doc['insulinaCalculada'] ?? 0)
                                              .toDouble();
                                    }
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
                                key: ValueKey('sensor_$_refreshFlag'),
                                stream: _firestore
                                    .collection('usuarios')
                                    .doc(widget.principalUid)
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
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12.w,
                        mainAxisSpacing: 12.h,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.1,
                        children: [
                          IconCard(
                            key: const ValueKey('grid_alimentos'),
                            icon: Icons.food_bank,
                            title: 'Alimentos',
                            subtitle: 'Explora alimentos',
                            onTap: () => Navigator.pushNamed(
                                context, '/food_explorer'),
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
                            key: const ValueKey('grid_reporte'),
                            icon: Icons.bar_chart,
                            title: 'Reporte',
                            subtitle: 'Historial',
                            onTap: () =>
                                Navigator.pushNamed(context, '/report'),
                          ),
                          IconCard(
                            key: const ValueKey('grid_recetas'),
                            icon: Icons.receipt_rounded,
                            title: 'Recetas',
                            subtitle: 'Recetas recomendadas',
                            onTap: () => Navigator.pushNamed(
                                context, '/recipes_explorer'),
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

                        ],
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
