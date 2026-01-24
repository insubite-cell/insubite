import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../design_system/calendar/app_range_calendar.dart';

class InsumosHistoryScreen extends StatefulWidget {
  const InsumosHistoryScreen({super.key});

  @override
  State<InsumosHistoryScreen> createState() => _InsumosHistoryScreenState();
}

class _InsumosHistoryScreenState extends State<InsumosHistoryScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  bool _loading = true;
  String? _principalUid;

  DateTime _from = DateTime.now().subtract(const Duration(days: 30));
  DateTime _to = DateTime.now();

  String _movimientoFilter = 'ambas'; // 'entrada', 'salida', 'ambas'
  String _tipoFilter = 'Todas';

  List<QueryDocumentSnapshot> _docs = [];
  Set<String> _tiposDisponibles = {};

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('usuarios').doc(user.uid).get();

    _principalUid =
        doc.data()?['lastValidated']?['principalUid'] ?? user.uid;

    await _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (_principalUid == null) return;

    setState(() => _loading = true);

    try {
      Query query = _firestore
          .collection('usuarios/$_principalUid/insumos')
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(_from))
          .where('createdAt',
              isLessThanOrEqualTo:
                  Timestamp.fromDate(_to.add(const Duration(days: 1))))
          .orderBy('createdAt', descending: true);

      if (_movimientoFilter != 'ambas') {
        query = query.where('movimiento', isEqualTo: _movimientoFilter);
      }

      if (_tipoFilter != 'Todas') {
        query = query.where('tipo', isEqualTo: _tipoFilter);
      }

      final snap = await query.get();

      // recolectamos todos los tipos disponibles para el dropdown
      final tiposSet = <String>{};
      for (var d in snap.docs) {
        tiposSet.add(d['tipo']);
      }

      setState(() {
        _docs = snap.docs;
        _tiposDisponibles = tiposSet;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar historial: $e')),
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
            // ------------------- RANGO DE FECHAS -------------------
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

            // ------------------- FILTROS -------------------
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _movimientoFilter,
                    items: const [
                      DropdownMenuItem(value: 'ambas', child: Text('Ambas')),
                      DropdownMenuItem(value: 'entrada', child: Text('Entradas')),
                      DropdownMenuItem(value: 'salida', child: Text('Salidas')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _movimientoFilter = v);
                        _loadHistory();
                      }
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: DropdownButton<String>(
                    value: _tipoFilter,
                    items: ['Todas', ..._tiposDisponibles].map((tipo) {
                      return DropdownMenuItem(value: tipo, child: Text(tipo));
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _tipoFilter = v);
                        _loadHistory();
                      }
                    },
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // ------------------- LISTA -------------------
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _docs.isEmpty
                      ? const Center(child: Text('No hay registros en este período'))
                      : ListView.builder(
                          itemCount: _docs.length,
                          itemBuilder: (_, i) {
                            final d = _docs[i];
                            final fecha = (d['createdAt'] as Timestamp).toDate();
                            final movimiento = d['movimiento'] as String? ?? '';

                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 6.h),
                              child: ListTile(
                                leading: Icon(
                                  movimiento == 'entrada'
                                      ? Icons.add_box_outlined
                                      : Icons.indeterminate_check_box,
                                  color: movimiento == 'entrada'
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                title: Text(d['tipo']),
                                subtitle: Text(
                                  '${movimiento.toUpperCase()} – ${DateFormat('dd/MM/yyyy – HH:mm').format(fecha)}',
                                ),
                                trailing: Text(
                                  d['cantidad'].toString(),
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: movimiento == 'entrada'
                                        ? Colors.green
                                        : Colors.red,
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
