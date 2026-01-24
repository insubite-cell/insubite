import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insubite/design_system/buttons/app_button.dart';
import 'package:insubite/design_system/inputs/app_text_field.dart';

class GlucoseDeviceScreen extends StatefulWidget {
  const GlucoseDeviceScreen({super.key});

  @override
  State<GlucoseDeviceScreen> createState() => _GlucoseDeviceScreenState();
}

class _GlucoseDeviceScreenState extends State<GlucoseDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _numeroSerieController = TextEditingController();
  DateTime? _fechaInicio;
  DateTime? _fechaCaducidad;
  bool _loading = false;

  int? _selectedMarcaId;
  String? _selectedMarcaNombre;
  int? _selectedModeloId;
  String? _selectedModeloNombre;
  int? _selectedModeloVigenciaDias;

  DateTime? _filterDesde;
  DateTime? _filterHasta;

  // 🔹 Usuario principal y flag secundario
  String? _principalUid;
  // ignore: unused_field
  bool _isSecondary = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();
    final data = doc.data() ?? {};

    _principalUid = data['lastValidated']?['principalUid']?.toString() ?? user.uid;
    _isSecondary = _principalUid != user.uid;

    if (mounted) setState(() {});
  }

  /// Devuelve texto con días y horas restantes
  String _tiempoRestanteText(DateTime expiryDate) {
    final now = DateTime.now();
    final diff = expiryDate.difference(now);
    if (diff.isNegative) return 'Venció';
    final dias = diff.inDays;
    final horas = diff.inHours % 24;
    if (dias > 0) {
      return 'Faltan $dias días y $horas horas';
    } else {
      return 'Faltan $horas horas';
    }
  }

  void _calcularFechaCaducidad() {
    if (_fechaInicio != null && _selectedModeloVigenciaDias != null) {
      _fechaCaducidad =
          _fechaInicio!.add(Duration(days: _selectedModeloVigenciaDias!));
    }
  }

  Future<void> _guardarSensor() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaInicio == null || _selectedMarcaId == null || _selectedModeloId == null) {
      return;
    }

    _calcularFechaCaducidad();
    if (_fechaCaducidad == null || _principalUid == null) return;

    setState(() => _loading = true);

    try {
      final userRef =
          FirebaseFirestore.instance.collection('usuarios').doc(_principalUid);

      // Guardar createdAt
      final now = DateTime.now();
      await userRef.set({'createdAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true));

      // Ajustar fechaCaducidad para mantener la misma hora que createdAt
      final fechaCaducidadConHora = DateTime(
        _fechaCaducidad!.year,
        _fechaCaducidad!.month,
        _fechaCaducidad!.day,
        now.hour,
        now.minute,
        now.second,
      );

      await userRef.collection('sensores').add({
        'marca_id': _selectedMarcaId,
        'marca_nombre': _selectedMarcaNombre,
        'modelo_id': _selectedModeloId,
        'modelo_nombre': _selectedModeloNombre,
        'numero_serie': _numeroSerieController.text.trim(),
        'fecha_inicio': Timestamp.fromDate(_fechaInicio!),
        'fecha_caducidad': Timestamp.fromDate(fechaCaducidadConHora),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Reset form
      _numeroSerieController.clear();
      setState(() {
        _selectedMarcaId = null;
        _selectedMarcaNombre = null;
        _selectedModeloId = null;
        _selectedModeloNombre = null;
        _selectedModeloVigenciaDias = null;
        _fechaInicio = null;
        _fechaCaducidad = null;
      });
    } catch (e) {
      debugPrint('❌ Error guardando sensor: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _eliminarSensor(String docId) async {
    if (_principalUid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_principalUid)
          .collection('sensores')
          .doc(docId)
          .delete();
    } catch (e) {
      debugPrint('❌ Error eliminando sensor: $e');
    }
  }

  Future<void> _seleccionarFechaInicio() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _fechaInicio) {
      setState(() {
        _fechaInicio = picked;
        _calcularFechaCaducidad();
      });
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _sensoresStream() {
    if (_principalUid == null) return const Stream.empty();
    var ref = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(_principalUid)
        .collection('sensores')
        .orderBy('createdAt', descending: true);

    if (_filterDesde != null) {
      ref = ref.where('fecha_inicio', isGreaterThanOrEqualTo: _filterDesde);
    }
    if (_filterHasta != null) {
      ref = ref.where('fecha_inicio', isLessThanOrEqualTo: _filterHasta);
    }
    return ref.snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _marcasStream() {
    return FirebaseFirestore.instance.collection('marcas_sensores').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _modelosStream() {
    if (_selectedMarcaId == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('modelos_sensores')
        .where('marca_id', isEqualTo: _selectedMarcaId)
        .snapshots();
  }

  Widget _buildDropdowns() {
    return Column(
      children: [
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _marcasStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();
            final marcas = snapshot.data!.docs;
            return DropdownButtonFormField<int>(
              initialValue: _selectedMarcaId,
              decoration: InputDecoration(
                labelText: "Marca",
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              items: marcas
                  .map((doc) => DropdownMenuItem<int>(
                        value: doc.data()['id'],
                        child: Text(doc.data()['nombre'], style: TextStyle(fontSize: 14.sp)),
                      ))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedMarcaId = val;
                  _selectedMarcaNombre =
                      marcas.firstWhere((m) => m['id'] == val)['nombre'];
                  _selectedModeloId = null;
                  _selectedModeloNombre = null;
                  _selectedModeloVigenciaDias = null;
                });
              },
              validator: (v) => v == null ? 'Seleccione una marca' : null,
            );
          },
        ),
        SizedBox(height: 12.h),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _modelosStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            final modelos = snapshot.data!.docs;
            return DropdownButtonFormField<int>(
              initialValue: _selectedModeloId,
              decoration: InputDecoration(
                labelText: "Modelo",
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              items: modelos
                  .map((doc) => DropdownMenuItem<int>(
                        value: doc.data()['id'],
                        child: Text(doc.data()['nombre'], style: TextStyle(fontSize: 14.sp)),
                      ))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedModeloId = val;
                  final modelo =
                      modelos.firstWhere((m) => m['id'] == val).data();
                  _selectedModeloNombre = modelo['nombre'];
                  _selectedModeloVigenciaDias =
                      (modelo['vigencia_dias'] as num).toInt();
                  _calcularFechaCaducidad();
                });
              },
              validator: (v) => v == null ? 'Seleccione un modelo' : null,
            );
          },
        ),
      ],
    );
  }

  Widget _buildSensorForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDropdowns(),
          SizedBox(height: 12.h),
          AppTextField(
          controller: _numeroSerieController,
          label: 'Número de Serie',
          contentPadding:
              EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        ),

          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  _fechaInicio == null
                      ? 'Sin fecha de inicio'
                      : 'Inicio: ${_fechaInicio!.day}/${_fechaInicio!.month}/${_fechaInicio!.year}',
                  style: TextStyle(fontSize: 14.sp),
                ),
              ),
              TextButton(
                onPressed: _seleccionarFechaInicio,
                child: Text("Seleccionar fecha", style: TextStyle(fontSize: 14.sp)),
              ),
            ],
          ),
          if (_fechaCaducidad != null)
            Text(
              "Caducidad: ${_fechaCaducidad!.day}/${_fechaCaducidad!.month}/${_fechaCaducidad!.year} (${_tiempoRestanteText(_fechaCaducidad!)})",
              style: TextStyle(fontSize: 14.sp, color: Colors.red),
            ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: 'Guardar Sensor',
              loading: _loading,
              onPressed: _guardarSensor,
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildSensorList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _sensoresStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(child: Text("No hay sensores guardados", style: TextStyle(fontSize: 14.sp)));
        }
        return ListView.builder(
          padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 12.w),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final docId = docs[index].id;
            final caducidad = data['fecha_caducidad']?.toDate();
            return Card(
              margin: EdgeInsets.symmetric(vertical: 6.h),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              child: ListTile(
                title: Text("${data['marca_nombre']} - ${data['modelo_nombre']}", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                subtitle: Text(
                  "N° Serie: ${data['numero_serie'] ?? '-'}\n"
                  "Inicio: ${data['fecha_inicio']?.toDate().day}/${data['fecha_inicio']?.toDate().month}/${data['fecha_inicio']?.toDate().year}\n"
                  "Caduca: ${caducidad?.day}/${caducidad?.month}/${caducidad?.year} (${caducidad != null ? _tiempoRestanteText(caducidad) : '-'})",
                  style: TextStyle(fontSize: 13.sp),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red, size: 24.sp),
                  onPressed: () => _eliminarSensor(docId),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Gestión de Sensores", style: TextStyle(fontSize: 18.sp))),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSensorForm(),
                ],
              ),
            ),
          ),
          Divider(height: 1.h, thickness: 1.h),
          Expanded(flex: 3, child: _buildSensorList()),
        ],
      ),
    );
  }
}
