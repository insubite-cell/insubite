import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../design_system/calendar/app_range_calendar.dart';

class InsulinReportScreen extends StatefulWidget {
  const InsulinReportScreen({super.key});

  @override
  State<InsulinReportScreen> createState() => _InsulinReportScreenState();
}

class _InsulinReportScreenState extends State<InsulinReportScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  bool _loading = true;
  double _totalInsulin = 0;
  double _avgPerDay = 0;

  DateTime _from = DateTime.now().subtract(const Duration(days: 7));
  DateTime _to = DateTime.now();

  String? _principalUid;

  @override
  void initState() {
    super.initState();
    _loadUserAndInsulinData();
  }

  Future<void> _loadUserAndInsulinData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('usuarios').doc(user.uid).get();
      final data = doc.data() ?? {};

      _principalUid =
          data['lastValidated']?['principalUid']?.toString() ?? user.uid;

      await _loadInsulinData();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al cargar datos del usuario")),
      );
    }
  }

  Future<void> _loadInsulinData() async {
    if (_principalUid == null) return;

    setState(() => _loading = true);

    try {
      final snapshot = await _firestore
          .collection("usuarios/$_principalUid/calculos_carbohidratos")
          .where("fecha",
              isGreaterThanOrEqualTo: Timestamp.fromDate(_from))
          .where("fecha",
              isLessThanOrEqualTo: Timestamp.fromDate(_to))
          .get();

      double totalInsulin = 0;
      Map<String, double> insulinPerDay = {};

      for (var doc in snapshot.docs) {
        final dateKey =
            (doc['fecha'] as Timestamp).toDate().toLocal().toString().split(' ')[0];
        final insulina =
            (doc['insulinaCalculada'] as num?)?.toDouble() ?? 0;

        totalInsulin += insulina;
        insulinPerDay[dateKey] =
            (insulinPerDay[dateKey] ?? 0) + insulina;
      }

      final totalDays = _to.difference(_from).inDays + 1;
      final avgPerDay = totalDays > 0 ? totalInsulin / totalDays : 0.0;

      if (!mounted) return;

      setState(() {
        _totalInsulin = totalInsulin;
        _avgPerDay = avgPerDay;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al cargar historial de insulina")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reporte de Insulina")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16.w),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppRangeCalendar(
                      startDate: _from,
                      endDate: _to,
                      onPickStart: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _from,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (d != null && mounted) {
                          setState(() => _from = d);
                          _loadInsulinData();
                        }
                      },
                      onPickEnd: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _to,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (d != null && mounted) {
                          setState(() => _to = d);
                          _loadInsulinData();
                        }
                      },
                    ),
                    SizedBox(height: 16.h),
                    _buildStatCard(
                      title: "Total de insulina aplicada",
                      value: "${_totalInsulin.toStringAsFixed(2)} U",
                      icon: Icons.bloodtype,
                      color: Colors.redAccent,
                    ),
                    _buildStatCard(
                      title: "Promedio por día",
                      value: "${_avgPerDay.toStringAsFixed(2)} U",
                      icon: Icons.show_chart,
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
        leading: Icon(icon, color: color, size: 32.sp),
        title: Text(title, style: TextStyle(fontSize: 16.sp)),
        trailing: Text(
          value,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}
