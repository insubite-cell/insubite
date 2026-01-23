// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insubite_new/design_system/buttons/app_button.dart';
import 'package:insubite_new/design_system/inputs/app_text_field.dart';

class FavoriteFoodsScreen extends StatefulWidget {
  const FavoriteFoodsScreen({super.key, required String principalUid});

  @override
  FavoriteFoodsScreenState createState() => FavoriteFoodsScreenState();
}

class FavoriteFoodsScreenState extends State<FavoriteFoodsScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;
  final ImagePicker picker = ImagePicker();

  final Map<String, bool> expandedFoods = {};

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getUidToUse(),
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

        final uid = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text('Alimentos Favoritos', style: TextStyle(fontSize: 20.sp)),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: firestore.collection('usuarios/$uid/favoritos').snapshots(),
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
                      leading: GestureDetector(
                        onTap: () => _addImage(uid, id, alimento),
                        child: _buildImage(alimento['imagen']),
                      ),
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
                            onPressed: () => _editFavorito(uid, id, alimento),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red, size: 24.sp),
                            onPressed: () => _deleteFavorito(uid, id),
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

  Future<String> _getUidToUse() async {
    final user = auth.currentUser;
    if (user == null) return '';

    final userDoc = await firestore.collection('usuarios').doc(user.uid).get();
    final userData = userDoc.data();
    if (userData == null) return '';

    if (userData['isSecondary'] == true &&
        userData['lastValidated'] != null &&
        userData['lastValidated']['principalUid'] != null) {
      return userData['lastValidated']['principalUid'];
    }

    return user.uid;
  }

  List<Widget> _buildAlimentoDetails(
      Map<String, dynamic> alimento, bool isExpanded) {
    final entries = alimento.entries
        .where((e) =>
            !['nombre', 'descripcion', 'imagen', 'id'].contains(e.key))
        .toList();

    final visible = isExpanded ? entries : entries.take(5);

    String formatValue(dynamic value) {
      if (value is Map &&
          value.containsKey('cantidad') &&
          value.containsKey('unidad')) {
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

  Future<void> _addImage(
      String uid, String docId, Map<String, dynamic> alimento) async {
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 80,
    );

    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final storageRef =
        storage.ref().child('usuarios/$uid/favoritos/$docId.png');

    await storageRef.putFile(file);
    final downloadUrl = await storageRef.getDownloadURL();

    if (!mounted) return;
    await firestore
        .collection('usuarios/$uid/favoritos')
        .doc(docId)
        .update({'imagen': downloadUrl});
  }

  Future<void> _editFavorito(
      String uid, String docId, Map<String, dynamic> alimento) async {
    final nombreController = TextEditingController(text: alimento['nombre']);
    final carboController =
        TextEditingController(text: alimento['carbohidratos']?.toString());
    final azucarController =
        TextEditingController(text: alimento['azucares']?.toString());
    final proteinaController =
        TextEditingController(text: alimento['proteinas']?.toString());
    final grasaController =
        TextEditingController(text: alimento['grasas']?.toString());
    final porcionController =
        TextEditingController(text: alimento['porcion']?.toString());

    String? newImage = alimento['imagen'];

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Editar alimento', style: TextStyle(fontSize: 18.sp)),
        content: SingleChildScrollView(
          child: Column(
            children: [
              if (newImage != null && newImage!.isNotEmpty)
                Image.network(newImage!, width: 100.w, height: 100.h),
              SizedBox(height: 12.h),
              AppButton(
                label: 'Cambiar imagen',
                leading: Icon(Icons.image, size: 20.sp),
                onPressed: () async {
                  final XFile? pickedFile =
                      await picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile == null) return;

                  final file = File(pickedFile.path);
                  final storageRef = storage
                      .ref()
                      .child('usuarios/$uid/favoritos/$docId.png');

                  await storageRef.putFile(file);
                  newImage = await storageRef.getDownloadURL();
                  if (mounted) setState(() {});
                },
              ),
              SizedBox(height: 12.h),
              AppTextField(
              controller: nombreController,
              label: 'Nombre',
            ),

              AppTextField(
                controller: carboController,
                label: 'Carbohidratos',
                keyboardType: TextInputType.number,
              ),

              AppTextField(
                controller: azucarController,
                label: 'Azúcares',
                keyboardType: TextInputType.number,
              ),

              AppTextField(
                controller: proteinaController,
                label: 'Proteínas',
                keyboardType: TextInputType.number,
              ),

              AppTextField(
                controller: grasaController,
                label: 'Grasas',
                keyboardType: TextInputType.number,
              ),

              AppTextField(
                controller: porcionController,
                label: 'Porción',
              ),

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
              await firestore
                  .collection('usuarios/$uid/favoritos')
                  .doc(docId)
                  .update({
                'nombre': nombreController.text,
                'carbohidratos': double.tryParse(carboController.text) ?? 0,
                'azucares': double.tryParse(azucarController.text) ?? 0,
                'proteinas': double.tryParse(proteinaController.text) ?? 0,
                'grasas': double.tryParse(grasaController.text) ?? 0,
                'porcion': porcionController.text,
                'imagen': newImage ?? '',
              });

              if (!mounted) return;
              Navigator.pop(dialogContext);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFavorito(String uid, String docId) async {
    await firestore.collection('usuarios/$uid/favoritos').doc(docId).delete();
  }

  Widget _buildImage(String? imagen) {
    if (imagen != null && imagen.isNotEmpty) {
      return Image.network(imagen, width: 50.w, height: 50.h, fit: BoxFit.cover);
    }
    return Icon(Icons.fastfood, size: 50.sp);
  }
}
