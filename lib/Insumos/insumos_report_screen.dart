import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../design_system/calendar/app_range_calendar.dart';

class InsumosHistoryScreen extends StatefulWidget {
  const InsumosHistoryScreen({super.key});

  @override
  State<InsumosHistoryScreen> createState() =>
      _InsumosHistoryScreenState();
}

class _InsumosHistoryScreenState extends State<InsumosHistoryScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  bool _loading = true;
  String? _principalUid;

  DateTime _from = DateTime.now().subtract(const Duration(days: 30));
  DateTime _to = DateTime.now();

  List<QueryDocumentSnapshot> _docs = [];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc =
        await _firestore.collection('usuarios').doc(user.uid).get();

    _principalUid =
        doc.data()?['lastValidated']?['principalUid'] ?? user.uid;

    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (_principalUid == null) return;

    setState(() => _loading = true);

    try {
      final snap = await _firestore
          .collection('usuarios/$_principalUid/insumos')
          .where('movimiento', isEqualTo: 'entrada')
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(_from),
          )
          .where(
            'createdAt',
            isLessThanOrEqualTo:
                Timestamp.fromDate(_to.add(const Duration(days: 1))),
          )
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _docs = snap.docs;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar historial')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de Insumos')),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
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
                if (d != null) {
                  setState(() => _from = d);
                  _loadHistory();
                }
              },
              onPickEnd: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _to,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (d != null) {
                  setState(() => _to = d);
                  _loadHistory();
                }
              },
            ),

            SizedBox(height: 16.h),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _docs.isEmpty
                      ? const Center(
                          child: Text('No hay entradas en este período'),
                        )
                      : ListView.builder(
                          itemCount: _docs.length,
                          itemBuilder: (_, i) {
                            final d = _docs[i];
                            final fecha = (d['createdAt'] as Timestamp)
                                .toDate();

                            return Card(
                              margin:
                                  EdgeInsets.symmetric(vertical: 6.h),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.add_box_outlined,
                                  color: Colors.green,
                                ),
                                title: Text(d['tipo']),
                                subtitle: Text(
                                  DateFormat('dd/MM/yyyy – HH:mm')
                                      .format(fecha),
                                ),
                                trailing: Text(
                                  d['cantidad'].toString(),
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
