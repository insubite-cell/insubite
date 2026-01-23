import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../design_system/calendar/app_range_calendar.dart';

class InsumosReportScreenSimple extends StatefulWidget {
  const InsumosReportScreenSimple({super.key});

  @override
  State<InsumosReportScreenSimple> createState() =>
      _InsumosReportScreenSimpleState();
}

class _InsumosReportScreenSimpleState
    extends State<InsumosReportScreenSimple> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  bool _loading = false;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();

  Map<String, int> _totals = {};
  String? _principalUid;

  final Map<String, IconData> _icons = {
    'insulina': Icons.bloodtype,
    'jeringa': Icons.medical_services,
    'glucómetro': Icons.monitor_heart,
    'aguja': Icons.medical_services,
    'tiras de cetonas': Icons.science,
    'lactosa': Icons.local_drink,
    'tiras de glucosa': Icons.bloodtype,
  };

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('usuarios').doc(user.uid).get();
    _principalUid = doc.data()?['lastValidated']?['principalUid'] ?? user.uid;

    _loadInsumos();
  }

  Future<void> _loadInsumos() async {
    if (_principalUid == null) return;
    setState(() => _loading = true);

    final snap =
        await _firestore.collection('usuarios/$_principalUid/insumos').get();

    final map = <String, int>{};
    for (final d in snap.docs) {
      map[d['tipo']] =
          (map[d['tipo']] ?? 0) + (d['cantidad'] as num).toInt();
    }

    setState(() {
      _totals = map;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reporte de Insumos")),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            AppRangeCalendar(
              startDate: _startDate,
              endDate: _endDate,
              onPickStart: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (d != null) {
                  setState(() => _startDate = d);
                  _loadInsumos();
                }
              },
              onPickEnd: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _endDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (d != null) {
                  setState(() => _endDate = d);
                  _loadInsumos();
                }
              },
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      children: _totals.entries
                          .map(
                            (e) => Card(
                              margin: EdgeInsets.symmetric(vertical: 6.h),
                              child: ListTile(
                                leading: Icon(
                                  _icons[e.key.toLowerCase()] ??
                                      Icons.inventory,
                                  color: Colors.blue,
                                ),
                                title: Text(e.key),
                                trailing: Text(
                                  e.value.toString(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
