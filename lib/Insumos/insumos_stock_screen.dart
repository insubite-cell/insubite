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

  /// stock final por tipo
  final Map<String, int> _stock = {};

  final Map<String, IconData> _icons = {
    'tiras de glucosa': Icons.bloodtype,
    'tiras de cetonas': Icons.science,
    'agujas': Icons.medical_services,
    'lancetas': Icons.healing,
  };

  @override
  void initState() {
    super.initState();
    _loadUserAndStock();
  }

  Future<void> _loadUserAndStock() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc =
        await _firestore.collection('usuarios').doc(user.uid).get();

    _principalUid =
        doc.data()?['lastValidated']?['principalUid'] ?? user.uid;

    await _loadStock();
  }

  Future<void> _loadStock() async {
    if (_principalUid == null) return;

    setState(() => _loading = true);

    final snap = await _firestore
        .collection('usuarios/$_principalUid/insumos')
        .get();

    final Map<String, int> stockTemp = {};

    for (final d in snap.docs) {
      final tipo = (d['tipo'] as String).toLowerCase();
      final cantidad = (d['cantidad'] as num).toInt();
      final movimiento = d['movimiento'] as String? ?? 'salida';

      stockTemp[tipo] ??= 0;

      if (movimiento == 'entrada') {
        stockTemp[tipo] = stockTemp[tipo]! + cantidad;
      } else {
        stockTemp[tipo] = stockTemp[tipo]! - cantidad;
      }
    }

    setState(() {
      _stock
        ..clear()
        ..addAll(stockTemp);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock y alertas'),
      ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: ListTile(
                          leading: Icon(
                            _icons[e.key] ?? Icons.inventory_2,
                            color: isLow ? Colors.red : Colors.blue,
                          ),
                          title: Text(
                            e.key,
                            style: TextStyle(fontSize: 16.sp),
                          ),
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
