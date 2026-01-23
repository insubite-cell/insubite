import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/design_system/theme/app_search_field.dart';

/// =======================
/// Modelo de alimento
/// =======================
class Alimento {
  final String id;
  final String nombre;
  final Map<String, dynamic> nutrientes;
  final Map<String, dynamic> nutrientesExtras;

  Alimento({
    required this.id,
    required this.nombre,
    required this.nutrientes,
    required this.nutrientesExtras,
  });

  factory Alimento.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final nutrientes = <String, dynamic>{};
    final extras = <String, dynamic>{};

    final keysToInclude = [
      'carbohidratos',
      'proteinas',
      'grasas_totales',
      'fibra',
      'energia',
    ];

    data.forEach((key, value) {
      if (keysToInclude.contains(key)) {
        nutrientes[key] = value;
      } else if (key != 'id' && key != 'nombre') {
        extras[key] = value;
      }
    });

    return Alimento(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      nutrientes: nutrientes,
      nutrientesExtras: extras,
    );
  }
}

/// =======================
/// Provider
/// =======================
class AlimentosProvider extends ChangeNotifier {
  final FirebaseFirestore firestore;

  List<Alimento> allAlimentos = [];
  List<Alimento> alimentos = [];
  bool isLoading = false;

  AlimentosProvider({required this.firestore});

  Future<void> loadAllAlimentos() async {
    isLoading = true;
    notifyListeners();

    try {
      final snapshot = await firestore
          .collection('alimentos_maestro')
          .orderBy('nombre')
          .get();

      allAlimentos =
          snapshot.docs.map((d) => Alimento.fromFirestore(d)).toList();
      alimentos = List.from(allAlimentos);
    } catch (e) {
      debugPrint('Error cargando alimentos: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  void search(String query) {
    final q = query.toLowerCase();

    if (q.isEmpty) {
      alimentos = List.from(allAlimentos);
    } else {
      alimentos = allAlimentos
          .where((a) => a.nombre.toLowerCase().contains(q))
          .toList();
    }
    notifyListeners();
  }
}

/// =======================
/// Pantalla principal
/// =======================
class FoodManagerScreen extends StatefulWidget {
  const FoodManagerScreen({super.key});

  @override
  State<FoodManagerScreen> createState() => _FoodManagerScreenState();
}

class _FoodManagerScreenState extends State<FoodManagerScreen> {
  late final AlimentosProvider provider;
  final user = FirebaseAuth.instance.currentUser!;

  final Map<String, bool> _expanded = {};
  Set<String> favoritos = {};

  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    provider = AlimentosProvider(firestore: FirebaseFirestore.instance);
    provider.loadAllAlimentos();
    _loadFavoritos();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavoritos() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .collection('favoritos')
        .get();

    setState(() {
      favoritos = snapshot.docs.map((d) => d.id).toSet();
    });
  }

  Future<void> _toggleFavorito(Alimento a) async {
    final favRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .collection('favoritos')
        .doc(a.id);

    if (favoritos.contains(a.id)) {
      await favRef.delete();
      setState(() => favoritos.remove(a.id));
    } else {
      await favRef.set({'nombre': a.nombre, ...a.nutrientes});
      setState(() => favoritos.add(a.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ChangeNotifierProvider.value(
        value: provider,
        child: Consumer<AlimentosProvider>(
          builder: (context, prov, _) {
            return Scaffold(
              appBar: AppBar(
                title: Text(
                  'Alimentos Maestro',
                  style: TextStyle(fontSize: 18.sp),
                ),
                bottom: PreferredSize(
                  preferredSize: Size.fromHeight(60.h),
                  child: Padding(
                    padding: EdgeInsets.all(8.w),
                    child: AppSearchField(
                      controller: _searchController,
                      hint: 'Buscar alimento...',
                      onChanged: prov.search,
                    ),
                  ),
                ),
              ),
              body: prov.isLoading && prov.alimentos.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: prov.alimentos.length,
                      itemBuilder: (context, index) {
                        final a = prov.alimentos[index];
                        final isExpanded = _expanded[a.id] ?? false;

                        final visible = a.nutrientes.entries.toList();
                        final extras = isExpanded
                            ? a.nutrientesExtras.entries.toList()
                            : [];

                        return Card(
                          margin: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          child: ListTile(
                            title: Text(
                              a.nombre,
                              style: TextStyle(fontSize: 16.sp),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ...visible.map((e) {
                                  final key = e.key.replaceAll('_', ' ');
                                  final label =
                                      key[0].toUpperCase() + key.substring(1);

                                  final value = e.value is Map &&
                                          e.value.containsKey('cantidad') &&
                                          e.value.containsKey('unidad')
                                      ? '${e.value['cantidad']} ${e.value['unidad']}'
                                      : e.value.toString();

                                  return Text(
                                    '$label: $value',
                                    style: TextStyle(fontSize: 12.sp),
                                  );
                                }),
                                ...extras.map((e) {
                                  final key = e.key.replaceAll('_', ' ');
                                  final label =
                                      key[0].toUpperCase() + key.substring(1);

                                  final value = e.value is Map &&
                                          e.value.containsKey('cantidad') &&
                                          e.value.containsKey('unidad')
                                      ? '${e.value['cantidad']} ${e.value['unidad']}'
                                      : e.value.toString();

                                  return Text(
                                    '$label: $value',
                                    style: TextStyle(fontSize: 12.sp),
                                  );
                                }),
                                if (a.nutrientesExtras.isNotEmpty)
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _expanded[a.id] = !isExpanded;
                                      });
                                    },
                                    child: Text(
                                      isExpanded ? 'Ver menos' : 'Ver más',
                                    ),
                                  ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                favoritos.contains(a.id)
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: favoritos.contains(a.id)
                                    ? Colors.red
                                    : null,
                              ),
                              onPressed: () => _toggleFavorito(a),
                            ),
                          ),
                        );
                      },
                    ),
            );
          },
        ),
      ),
    );
  }
}
