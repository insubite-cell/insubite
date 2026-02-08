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

    /// filtros UI
    String _movimientoFilter = 'ambas'; // entrada | salida | ambas
    String _tipoFilter = 'Todas';

    /// data
    List<QueryDocumentSnapshot> _allDocs = [];
    List<QueryDocumentSnapshot> _filteredDocs = [];
    Set<String> _tiposDisponibles = {};

    /// labels
    final Map<String, String> _labels = {
      'tiras_glucosa': 'Tiras de glucosa',
      'tiras_cetonas': 'Tiras de cetonas',
      'agujas': 'Agujas',
      'lancetas': 'Lancetas',
      'insulina_rapida': 'Insulina rápida',
      'insulina_lenta': 'Insulina lenta',
    };

    @override
    void initState() {
      super.initState();
      _loadUser();
    }

    // -------------------------------------------------------
    // NORMALIZACIÓN (MISMA QUE STOCK)
    // -------------------------------------------------------
    String _normalizeTipo(String raw) {
      return raw
          .toLowerCase()
          .replaceAll('á', 'a')
          .replaceAll('é', 'e')
          .replaceAll('í', 'i')
          .replaceAll('ó', 'o')
          .replaceAll('ú', 'u')
          .replaceAll(' ', '_');
    }

    // -------------------------------------------------------
    // USER
    // -------------------------------------------------------
    Future<void> _loadUser() async {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await _firestore.collection('usuarios').doc(user.uid).get();

      _principalUid =
          doc.data()?['lastValidated']?['principalUid'] ?? user.uid;

      await _loadHistory();
    }

    // -------------------------------------------------------
    // FIRESTORE → SOLO FECHAS
    // -------------------------------------------------------
    Future<void> _loadHistory() async {
      if (_principalUid == null) return;

      setState(() => _loading = true);

      try {
        final query = _firestore
            .collection('usuarios/$_principalUid/insumos')
            .where(
              'fecha',
              isGreaterThanOrEqualTo: Timestamp.fromDate(_from),
            )
            .where(
              'fecha',
              isLessThanOrEqualTo:
                  Timestamp.fromDate(_to.add(const Duration(days: 1))),
            )
            .orderBy('fecha', descending: true);


        final snap = await query.get();

        final tiposSet = <String>{};
        for (var d in snap.docs) {
          final tipoRaw = d['tipo'] as String;
          tiposSet.add(_normalizeTipo(tipoRaw));
        }

        setState(() {
          _allDocs = snap.docs;
          _tiposDisponibles = tiposSet;
          _applyFilters();
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

    // -------------------------------------------------------
    // FILTROS LOCALES (NO FIRESTORE)
    // -------------------------------------------------------
    void _applyFilters() {
      _filteredDocs = _allDocs.where((d) {
        final movimiento = d['movimiento'] as String? ?? '';
        final tipo = d['tipo_normalizado'] as String? ?? '';

        final okMovimiento =
            _movimientoFilter == 'ambas' ||
            movimiento == _movimientoFilter;

        final okTipo =
            _tipoFilter == 'Todas' ||
            tipo == _tipoFilter;

        return okMovimiento && okTipo;
      }).toList();
    }

    // -------------------------------------------------------
    // UI
    // -------------------------------------------------------
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: const Text('Historial de Insumos')),
        body: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              // ------------------- CALENDARIO (NO SE TOCA) -------------------
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
                        DropdownMenuItem(
                          value: 'ambas',
                          child: Text('Ambas'),
                        ),
                        DropdownMenuItem(
                          value: 'entrada',
                          child: Text('Entradas'),
                        ),
                        DropdownMenuItem(
                          value: 'salida',
                          child: Text('Salidas'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            _movimientoFilter = v;
                            _applyFilters();
                          });
                        }
                      },
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _tipoFilter,
                      items: [
                        const DropdownMenuItem(
                          value: 'Todas',
                          child: Text('Todas'),
                        ),
                        ..._tiposDisponibles.map((k) {
                          return DropdownMenuItem(
                            value: k,
                            child: Text(_labels[k] ?? k),
                          );
                        }),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            _tipoFilter = v;
                            _applyFilters();
                          });
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
                    : _filteredDocs.isEmpty
                        ? const Center(
                            child: Text('No hay registros en este período'),
                          )
                        : ListView.builder(
                            itemCount: _filteredDocs.length,
                            itemBuilder: (_, i) {
                              final d = _filteredDocs[i];
                              final fecha =
                                  (d['fecha'] as Timestamp).toDate();
                              final movimiento =
                                  d['movimiento'] as String? ?? '';
                              final tipoRaw = d['tipo'] as String;
                              final tipo = _normalizeTipo(tipoRaw);

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
                                  title: Text(_labels[tipo] ?? tipoRaw),
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
