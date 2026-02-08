import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class InsumosStockScreen extends StatefulWidget {
  const InsumosStockScreen({super.key});

  @override
  State<InsumosStockScreen> createState() => _InsumosStockScreenState();
}

class _InsumosStockScreenState extends State<InsumosStockScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  bool _loading = true;
  String? _principalUid;

  /// stock final por tipo (clave técnica)
  final Map<String, int> _stock = {};

  /// iconos por tipo
  final Map<String, IconData> _icons = {
    'tiras_glucosa': Icons.bloodtype,
    'tiras_cetonas': Icons.science,
    'agujas': Icons.medical_services,
    'lancetas': Icons.healing,
    'insulina_rapida': Icons.flash_on,
    'insulina_lenta': Icons.schedule,
  };

  /// labels UI
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
    _loadAll();
  }

  // --------------------------------------------------
  // HELPERS
  // --------------------------------------------------
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

  // --------------------------------------------------
  // LOAD
  // --------------------------------------------------
  Future<void> _loadAll() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc =
        await _firestore.collection('usuarios').doc(user.uid).get();

    _principalUid =
        userDoc.data()?['lastValidated']?['principalUid'] ?? user.uid;

    await _loadMedicalDefaults();
    await _loadStock();
  }

  /// 👉 asegura que las insulinas existan aunque no tengan movimientos
  Future<void> _loadMedicalDefaults() async {
    if (_principalUid == null) return;

    final medicalDoc = await _firestore
        .collection('usuarios')
        .doc(_principalUid)
        .collection('datos_medicos')
        .doc('info')
        .get();

    final data = medicalDoc.data();
    if (data == null) return;

    if ((data['insulina_rapida'] ?? '').toString().isNotEmpty) {
      _stock['insulina_rapida'] ??= 0;
    }

    if ((data['insulina_lenta'] ?? '').toString().isNotEmpty) {
      _stock['insulina_lenta'] ??= 0;
    }
  }

  Future<void> _loadStock() async {
    if (_principalUid == null) return;

    setState(() => _loading = true);

    final snap = await _firestore
        .collection('usuarios/$_principalUid/insumos')
        .get();

    for (final d in snap.docs) {
      final tipo = _normalizeTipo(d['tipo'] as String);
      final cantidad = (d['cantidad'] as num).toInt();
      final movimiento = d['movimiento'] as String? ?? 'salida';

      _stock[tipo] ??= 0;

      if (movimiento == 'entrada') {
        _stock[tipo] = _stock[tipo]! + cantidad;
      } else {
        _stock[tipo] = _stock[tipo]! - cantidad;
      }
    }

    setState(() => _loading = false);
  }

  // --------------------------------------------------
  // UI
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stock y alertas')),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _stock.isEmpty
                ? const Center(child: Text('Sin datos de stock'))
                : ListView(
                    children: _stock.entries.map((e) {
                      final isLow = e.value <= 5;

                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 6.h),
                        child: ListTile(
                          leading: Icon(
                            _icons[e.key] ?? Icons.inventory_2,
                            color: isLow ? Colors.red : Colors.blue,
                          ),
                          title: Text(_labels[e.key] ?? e.key),
                          subtitle: isLow
                              ? const Text(
                                  '⚠ Stock bajo',
                                  style: TextStyle(color: Colors.red),
                                )
                              : null,
                          trailing: Text(
                            e.value.toString(),
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: isLow ? Colors.red : Colors.black,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
      ),
    );
  }
}
