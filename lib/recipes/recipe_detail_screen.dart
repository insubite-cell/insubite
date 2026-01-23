import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RecipeDetailScreen extends StatefulWidget {
  final String recetaId;
  const RecipeDetailScreen({super.key, required this.recetaId});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  Map<String, dynamic>? receta;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarReceta();
  }

  Future<void> _cargarReceta() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      Map<String, dynamic>? userReceta;

      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .collection('recetas')
            .doc(widget.recetaId)
            .get();
        if (doc.exists) userReceta = doc.data();
      }

      final masterDoc = await FirebaseFirestore.instance
          .collection('recetas_maestro')
          .doc(widget.recetaId)
          .get();

      if (!masterDoc.exists && userReceta == null) {
        setState(() {
          _error = 'Receta no encontrada';
          _loading = false;
        });
        return;
      }

      setState(() {
        receta = {...?masterDoc.data(), ...?userReceta};
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Widget _buildNutritionalInfo() {
    final hc = receta?['HC'];
    final fibra = receta?['Fibra'];
    final porcion = receta?['porcion'];

    if (hc == null && fibra == null && porcion == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Información nutricional:', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
        SizedBox(height: 8.h),
        if (hc != null) Text('HC: $hc', style: TextStyle(fontSize: 14.sp)),
        if (fibra != null) Text('Fibra: $fibra', style: TextStyle(fontSize: 14.sp)),
        if (porcion != null) Text('Porción: $porcion', style: TextStyle(fontSize: 14.sp)),
        SizedBox(height: 16.h),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, _) => Scaffold(
        appBar: AppBar(title: Text(receta?['titulo'] ?? 'Receta')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('Error: $_error'))
                : SingleChildScrollView(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (receta?['imagen_url'] != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12.r),
                            child: Image.network(
                              receta!['imagen_url'],
                              height: 200.h,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        SizedBox(height: 16.h),
                        Text(
                          receta?['titulo'] ?? 'Sin título',
                          style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8.h),
                        if (receta?['descripcion'] != null)
                          Text(
                            receta!['descripcion'],
                            style: TextStyle(fontSize: 14.sp),
                          ),
                        SizedBox(height: 16.h),
                        _buildNutritionalInfo(),
                        if (receta?['ingredientes'] != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Ingredientes:', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
                              SizedBox(height: 8.h),
                              ...List<Widget>.from(
                                (receta!['ingredientes'] as List<dynamic>)
                                    .map((ing) => Padding(
                                          padding: EdgeInsets.symmetric(vertical: 2.h),
                                          child: Text('- $ing', style: TextStyle(fontSize: 14.sp)),
                                        )),
                              ),
                              SizedBox(height: 16.h),
                            ],
                          ),
                        if (receta?['preparacion'] != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Preparación:', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
                              SizedBox(height: 8.h),
                              ...List<Widget>.from(
                                (receta!['preparacion'] as List<dynamic>).asMap().entries.map(
                                      (entry) => Padding(
                                        padding: EdgeInsets.symmetric(vertical: 4.h),
                                        child: Text('${entry.key + 1}. ${entry.value}', style: TextStyle(fontSize: 14.sp)),
                                      ),
                                    ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
