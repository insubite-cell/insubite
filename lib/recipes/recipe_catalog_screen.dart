import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../service/maestros_service.dart';
import 'recipe_detail_screen.dart';
import '../design_system/cards/list_nav_card.dart';

class RecipeCatalogScreen extends StatelessWidget {
  const RecipeCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final MaestrosService maestrosService = MaestrosService();
    final String uid = FirebaseAuth.instance.currentUser!.uid;

    Stream<List<Map<String, dynamic>>> userRecetasStream =
        FirebaseFirestore.instance
            .collection('usuarios')
            .doc(uid)
            .collection('recetas')
            .snapshots()
            .map(
              (snapshot) => snapshot.docs
                  .map((doc) => {'id': doc.id, ...doc.data()})
                  .toList(),
            );

    Stream<List<Map<String, dynamic>>> combinedStream = Rx.combineLatest2(
      maestrosService.recetas(),
      userRecetasStream,
      (List<Map<String, dynamic>> maestras,
          List<Map<String, dynamic>> userRecetas) {
        final Map<String, Map<String, dynamic>> map = {
          for (var r in maestras) r['id']: r
        };
        for (var r in userRecetas) {
          map[r['id']] = r;
        }
        final List<Map<String, dynamic>> merged = map.values.toList()
          ..sort(
            (a, b) =>
                (a['titulo'] ?? '').compareTo(b['titulo'] ?? ''),
          );
        return merged;
      },
    );

    return ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, _) => Scaffold(
        appBar: AppBar(
          title: const Text("Recetas"),
        ),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: combinedStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final recetas = snapshot.data ?? [];

            if (recetas.isEmpty) {
              return Center(
                child: Text(
                  'No hay recetas disponibles',
                  style: TextStyle(fontSize: 16.sp),
                ),
              );
            }

            return ListView.separated(
              padding: EdgeInsets.all(16.w),
              itemCount: recetas.length,
              separatorBuilder: (_, _) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                final receta = recetas[index];

                return ListNavCard(
                  icon: receta['editada_por_usuario'] == true
                      ? Icons.edit
                      : Icons.restaurant, // ICONO CONSERVADO ✔
                  title: receta['titulo'] ?? 'Sin título',
                  subtitle: receta['editada_por_usuario'] == true
                      ? 'Receta personalizada'
                      : 'Receta base',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            RecipeDetailScreen(recetaId: receta['id']),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
