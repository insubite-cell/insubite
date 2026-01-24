import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insubite/design_system/buttons/app_button.dart';
import 'package:insubite/design_system/inputs/app_text_field.dart';
import 'package:insubite/service/user_session_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoriteFoodsScreen extends StatefulWidget {
  const FavoriteFoodsScreen({super.key});

  @override
  FavoriteFoodsScreenState createState() => FavoriteFoodsScreenState();
}

class FavoriteFoodsScreenState extends State<FavoriteFoodsScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final Map<String, bool> expandedFoods = {};
  late String currentUid;
  late String effectiveUid;
  bool isSecondary = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: UserSessionService().getEffectiveUid(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Scaffold(
            body: Center(child: Text("No se pudo determinar el usuario")),
          );
        }

        effectiveUid = snapshot.data!;
        currentUid = FirebaseAuth.instance.currentUser!.uid;
        isSecondary = currentUid != effectiveUid;

        return Scaffold(
          appBar: AppBar(
            title: Text('Alimentos Favoritos', style: TextStyle(fontSize: 20.sp)),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: firestore.collection('usuarios/$effectiveUid/favoritos').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "Error cargando favoritos",
                    style: TextStyle(fontSize: 16.sp),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return Center(
                  child: Text(
                    'No hay alimentos favoritos.',
                    style: TextStyle(fontSize: 16.sp),
                  ),
                );
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final alimento = docs[index].data() as Map<String, dynamic>;
                  final id = docs[index].id;

                  expandedFoods[id] = expandedFoods[id] ?? false;
                  final isExpanded = expandedFoods[id]!;

                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    child: ListTile(
                      title: Text(
                        alimento['nombre'] ?? '',
                        style: TextStyle(fontSize: 16.sp),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ..._buildAlimentoDetails(alimento, isExpanded),
                          if (alimento.keys.length > 5)
                            Padding(
                              padding: EdgeInsets.only(top: 6.h),
                              child: AppButton(
                                label: isExpanded ? 'Ver menos' : 'Ver más',
                                outlined: true,
                                onPressed: () {
                                  if (!mounted) return;
                                  setState(() {
                                    expandedFoods[id] = !isExpanded;
                                  });
                                },
                              ),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue, size: 24.sp),
                            onPressed: () => _editFavorito(effectiveUid, id, alimento),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red, size: 24.sp),
                            onPressed: () => _deleteFavorito(effectiveUid, id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  List<Widget> _buildAlimentoDetails(Map<String, dynamic> alimento, bool isExpanded) {
    final entries = alimento.entries
        .where((e) => !['nombre', 'descripcion', 'imagen', 'id'].contains(e.key))
        .toList();

    final visible = isExpanded ? entries : entries.take(5);

    String formatValue(dynamic value) {
      if (value is Map && value.containsKey('cantidad') && value.containsKey('unidad')) {
        return "${value['cantidad']} ${value['unidad']}";
      }
      if (value is num) return value.toStringAsFixed(2);
      return value?.toString() ?? '-';
    }

    return visible
        .map(
          (e) => Text(
            "${e.key[0].toUpperCase()}${e.key.substring(1)}: ${formatValue(e.value)}",
            style: TextStyle(fontSize: 12.sp),
          ),
        )
        .toList();
  }

  Future<void> _editFavorito(String uid, String docId, Map<String, dynamic> alimento) async {
    final nombreController = TextEditingController(text: alimento['nombre']);
    final carboCantidadController = TextEditingController(
        text: alimento['carbohidratos']?['cantidad']?.toString() ?? '');
    final carboUnidadController =
        TextEditingController(text: alimento['carbohidratos']?['unidad'] ?? 'g');

    final azucarCantidadController = TextEditingController(
        text: alimento['azucares']?['cantidad']?.toString() ?? '');
    final azucarUnidadController =
        TextEditingController(text: alimento['azucares']?['unidad'] ?? 'g');

    final proteinaCantidadController = TextEditingController(
        text: alimento['proteinas']?['cantidad']?.toString() ?? '');
    final proteinaUnidadController =
        TextEditingController(text: alimento['proteinas']?['unidad'] ?? 'g');

    final grasaCantidadController = TextEditingController(
        text: alimento['grasas']?['cantidad']?.toString() ?? '');
    final grasaUnidadController =
        TextEditingController(text: alimento['grasas']?['unidad'] ?? 'g');

    final porcionController = TextEditingController(text: alimento['porcion'] ?? '');

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Editar alimento', style: TextStyle(fontSize: 18.sp)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(controller: nombreController, label: 'Nombre'),
              const SizedBox(height: 12),
              _buildMacroInput('Carbohidratos', carboCantidadController, carboUnidadController),
              _buildMacroInput('Azúcares', azucarCantidadController, azucarUnidadController),
              _buildMacroInput('Proteínas', proteinaCantidadController, proteinaUnidadController),
              _buildMacroInput('Grasas', grasaCantidadController, grasaUnidadController),
              const SizedBox(height: 12),
              AppTextField(controller: porcionController, label: 'Porción'),
            ],
          ),
        ),
        actions: [
          AppButton(
            label: 'Cancelar',
            outlined: true,
            onPressed: () => Navigator.pop(dialogContext),
          ),
          AppButton(
            label: 'Guardar',
            onPressed: () async {
              await firestore.collection('usuarios/$uid/favoritos').doc(docId).update({
                'nombre': nombreController.text,
                'carbohidratos': {
                  'cantidad': double.tryParse(carboCantidadController.text) ?? 0,
                  'unidad': carboUnidadController.text,
                },
                'azucares': {
                  'cantidad': double.tryParse(azucarCantidadController.text) ?? 0,
                  'unidad': azucarUnidadController.text,
                },
                'proteinas': {
                  'cantidad': double.tryParse(proteinaCantidadController.text) ?? 0,
                  'unidad': proteinaUnidadController.text,
                },
                'grasas': {
                  'cantidad': double.tryParse(grasaCantidadController.text) ?? 0,
                  'unidad': grasaUnidadController.text,
                },
                'porcion': porcionController.text,
              });

              if (!mounted) return;
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMacroInput(String label, TextEditingController cantidadController,
      TextEditingController unidadController) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: AppTextField(
                  controller: cantidadController,
                  label: 'Cantidad',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: AppTextField(
                  controller: unidadController,
                  label: 'Unidad',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFavorito(String uid, String docId) async {
    await firestore.collection('usuarios/$uid/favoritos').doc(docId).delete();
  }
}
