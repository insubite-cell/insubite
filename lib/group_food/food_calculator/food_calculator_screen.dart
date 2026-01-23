// main.dart
// ignore_for_file: unused_element, use_build_context_synchronously, unnecessary_to_list_in_spreads

import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insubite_new/design_system/buttons/app_button.dart';
import 'package:insubite_new/primary_users/dashboard_screen.dart';
import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../secondary_users/secondary_dashboard_screen.dart';
import 'calculos_aggregator_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, child) => MaterialApp(
        title: 'Calculadora de Bolo',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const FoodCalculatorScreen(),

      ),
    );
  }
}



class FoodCalculatorScreen extends StatefulWidget {
  const FoodCalculatorScreen({super.key});

  @override
  State<FoodCalculatorScreen> createState() => _FoodCalculatorScreenState();
}

class _FoodCalculatorScreenState extends State<FoodCalculatorScreen> {
  bool _isSaving = false;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final Logger logger = Logger();

  int _currentStep = 0;

  String? _mealType;
  String _searchSource = "General";
  String _searchQuery = '';
  final List<Map<String, dynamic>> _selectedFoods = [];
  List<Map<String, dynamic>> _allFoods = [];
  List<Map<String, dynamic>> _favoriteFoods = [];

  // Ratios dinámicos
  // ignore: prefer_final_fields
    double _carbsPorDosis = 0.0;     // ej: 10 g
    double _unidadesPorDosis = 0.0;  // ej: 1 U

  final _searchController = TextEditingController();
  final Map<String, TextEditingController> _carbControllers = {};
  final Map<String, TextEditingController> _portionControllers = {};
  Timer? _debounce;

  double? _userAdjustedInsulin;

  // 🔹 CORRECCIÓN: controller de insulina
  final TextEditingController _insulinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFoods();
    _loadFavoriteFoods();

    // Inicializar el controller con el valor calculado
    _insulinController.text = '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _insulinController.dispose(); // dispose del controller persistente
    _debounce?.cancel();
    super.dispose();
  }

  /// FUNCIONES PARA DEBUG DE USUARIO PRINCIPAL/SECUNDARIO
  Future<String?> _getUidPrincipalDebug() async {
  final user = _auth.currentUser;
  if (user == null) return null;

  final doc =
      await _firestore.collection('usuarios').doc(user.uid).get();

  final data = doc.data();
  if (data == null) return user.uid;

  // ✅ LEER DESDE lastValidated
  final principalUid =
      data['lastValidated']?['principalUid']?.toString();

  if (principalUid != null && principalUid.isNotEmpty) {
    logger.i("Usando UID PRINCIPAL: $principalUid");
    return principalUid;
  }

  logger.i("Usuario principal (uid propio): ${user.uid}");
  return user.uid;
}


    Future<void> _loadMedicalDataForMeal(String mealType) async {
      
  try {
    final uid = await _getUidPrincipalDebug();
    if (uid == null) {
      logger.w("No se obtuvo UID válido");
      return;
    }
    logger.w("🔥 UID USADO PARA RELACION_COMIDAS: $uid");
    final docRef = _firestore
        .collection("usuarios")
        .doc(uid)
        .collection("relacion_comidas")
        .doc("info");

    final doc = await docRef.get();

    if (!doc.exists) {
      logger.w("Documento info no existe para uid $uid");
      return;
    }

    final data = doc.data() ?? {};
    logger.i("Datos cargados de Firebase para $mealType: $data");

    // ignore: no_leading_underscores_for_local_identifiers
    double _toDouble(dynamic value) {
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
      return 0.0;
    }

    double carbsPorDosis = 0.0;
    double unidadesPorDosis = 0.0;

    switch (mealType.toLowerCase()) {
      case "desayuno":
        carbsPorDosis = _toDouble(data["desayuno_carb"]);
        unidadesPorDosis = _toDouble(data["desayuno_insulina"]);
        break;
      case "almuerzo":
        carbsPorDosis = _toDouble(data["almuerzo_carb"]);
        unidadesPorDosis = _toDouble(data["almuerzo_insulina"]);
        break;
      case "cena":
        carbsPorDosis = _toDouble(data["cena_carb"]);
        unidadesPorDosis = _toDouble(data["cena_insulina"]);
        break;
      case "merienda":
        carbsPorDosis = _toDouble(data["merienda_carb"]);
        unidadesPorDosis = _toDouble(data["merienda_insulina"]);
        break;
      default:
        logger.w("Tipo de comida desconocido: $mealType");
    }

      double calculatedDose = 0.0;

          if (carbsPorDosis > 0 && unidadesPorDosis > 0) {
            calculatedDose =
                (_totalCarbs / carbsPorDosis) * unidadesPorDosis;
          }

          setState(() {
            _carbsPorDosis = carbsPorDosis;
            _unidadesPorDosis = unidadesPorDosis;

            _insulinController.text = calculatedDose.toStringAsFixed(2);
            _userAdjustedInsulin = calculatedDose;
          });


    logger.i("CarbsPorDosis: $_carbsPorDosis, UnidadesPorDosis: $_unidadesPorDosis, Insulina calculada: $_userAdjustedInsulin");
  } catch (e, st) {
    logger.e("Error cargando datos médicos: $e\n$st");
  }
}




  Future<void> _loadFoods() async {
    try {
      final uid = await _getUidPrincipalDebug();
      if (uid == null) {
        setState(() {
          _allFoods = [
            {'id': 'm1', 'nombre': 'Pan', 'carbohidratos': {'cantidad': 25.0, 'unidad': 'g'}, 'porcion': '1 rebanada'},
            {'id': 'm2', 'nombre': 'Arroz', 'carbohidratos': {'cantidad': 28.0, 'unidad': 'g'}, 'porcion': '100g'},
            {'id': 'm3', 'nombre': 'Manzana', 'carbohidratos': {'cantidad': 15.0, 'unidad': 'g'}, 'porcion': '1 unidad'},
          ];
        });
        return;
      }

      final maestroSnap = await _firestore.collection("alimentos_maestro").get();
      final maestroFoods = maestroSnap.docs.map((d) => {"id": d.id, ...d.data()}).toList();

      final userDoc = await _firestore.collection("usuarios").doc(uid).get();
      final customFoods = List<Map<String, dynamic>>.from(userDoc.data()?['alimentos_custom'] ?? []);

      setState(() {
        _allFoods = [
          ...customFoods,
          ...maestroFoods.where((m) => !customFoods.any((c) => c['id'] == m['id'])),
        ];
      });
    } catch (e, st) {
      logger.w("Error loadFoods: $e\n$st");
    }
  }

  Future<void> _loadFavoriteFoods() async {
    try {
      final uid = await _getUidPrincipalDebug();
      if (uid == null) {
        setState(() {
          _favoriteFoods = [
            {'id': 'fav1', 'nombre': 'Pan', 'carbohidratos': {'cantidad': 25.0, 'unidad': 'g'}, 'porcion': '1 rebanada'}
          ];
        });
        return;
      }

      final snapshot = await _firestore.collection("usuarios").doc(uid).collection("favoritos").get();
      setState(() {
        _favoriteFoods = snapshot.docs.map((d) {
          final data = Map<String, dynamic>.from(d.data());
          return {"id": d.id, ...data};
        }).toList();
      });
    } catch (e, st) {
      logger.w("Error loadFavorites: $e\n$st");
    }
  }

    Future<void> _finalizeCalculation() async {
        if (_isSaving) return;
      setState(() {
        _isSaving = true;
      });

  final authUser = _auth.currentUser;
  if (authUser == null) {
  if (mounted) {
    setState(() => _isSaving = false);
  }
  return;
  }

  // 🔹 Obtener datos principal
  final userDoc = await _firestore.collection('usuarios').doc(authUser.uid).get();
  final userData = userDoc.data() ?? {};
  final principalData = userData['lastValidated'] ?? {};
  final principalUid = principalData['principalUid']?.toString() ?? authUser.uid;
  final principalEmail = principalData['email']?.toString() ?? authUser.email ?? '';
  final bool isSecondary = principalUid != authUser.uid;

  if (_mealType == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Debes elegir un tipo de comida")),
  );
  if (mounted) {
    setState(() => _isSaving = false);
  }
  return;
}


  try {
    // 🔹 Actualizar carbohidratos desde controllers
    for (var f in _selectedFoods) {
      final id = f['id']?.toString() ?? f['nombre'];
      final controller = _carbControllers[id];
      if (controller != null) {
        f['carbohidratos'] ??= {};
        f['carbohidratos']['cantidad'] = double.tryParse(controller.text) ?? 0.0;
      }
    }

    // 🔹 Guardar en Firestore
    await _firestore
        .collection("usuarios")
        .doc(principalUid)
        .collection("calculos_carbohidratos")
        .add({
      "fecha": Timestamp.now(),
      "tipoComida": _mealType,
      "alimentos": _selectedFoods,
      "totalCarbohidratos": double.parse(_totalCarbs.toStringAsFixed(2)),
      "insulinaCalculada": double.parse((_userAdjustedInsulin ?? _insulinDose).toStringAsFixed(2)),
      "relacion_usada": {
        "carbohidratos_por_dosis": _carbsPorDosis,
        "unidades_por_dosis": _unidadesPorDosis,
      },
    });


await CalculosAggregatorService().processCalculation(
  principalUid: principalUid,
  date: DateTime.now(),
  mealType: _mealType!,
  carbs: _totalCarbs,
  insulin: _userAdjustedInsulin ?? _insulinDose,
  alimentos: _selectedFoods, // <-- agregamos los alimentos elegidos
);





  } catch (e) {
  logger.e("Error guardando cálculo: $e");
  if (mounted) {
    setState(() => _isSaving = false);
  }
  return;
}


  // 🔹 Pregunta final
  final exit = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Cálculo guardado"),
      content: const Text("¿Querés guardar y salir?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No")),
        AppButton(
          label: "Sí",
          onPressed: () => Navigator.pop(context, true),
        )      ],
    ),
  );

  // 🔹 Reiniciar flag si el usuario cancela
  if (exit != true || !mounted) {
  if (mounted) {
    setState(() => _isSaving = false);
  }
  return;
}


  // 🔹 Navegar
  if (isSecondary) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => SecondaryDashboardScreen(
          principalUid: principalUid,
          principalEmail: principalEmail,
        ),
      ),
      (_) => false,
    );
  } else {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => DashboardScreen(principalUid: principalUid),
      ),
      (_) => false,
    );
  }

  // 🔹 Resetear flag para próxima operación
    if (mounted) {
    setState(() {
      _isSaving = false;
    });
  }

}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Calculadora de bolos")),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: _isSaving
          ? null
          : () async {
          if (_currentStep == 0 && _mealType != null) {
            await _loadMedicalDataForMeal(_mealType!);
          }

          if (_currentStep == 1 && _selectedFoods.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Debes seleccionar al menos 1 alimento")),
            );
            return;
          }

          if (_currentStep < 2) {
            setState(() => _currentStep++);
          } else {
            await _finalizeCalculation();
          }
        },
        onStepCancel: _isSaving
        ? null
        : () {

          if (_currentStep > 0) setState(() => _currentStep--);
        },
        steps: [
          Step(
            title: const Text("Tipo de comida"),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Elegí el tipo de comida:"),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _mealType,
                  hint: const Text("Elegir tipo de comida"),
                  onChanged: (val) async {
                    setState(() => _mealType = val);
                    if (val != null) {
                      await _loadMedicalDataForMeal(val);
                    }
                  },
                  items: ["Desayuno", "Almuerzo", "Cena", "Merienda"]
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                ),
              ],
            ),
            isActive: _currentStep == 0,
            state: _mealType == null ? StepState.indexed : StepState.complete,
          ),
          Step(
            title: const Text("Seleccionar alimentos"),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Buscar en:"),
                SizedBox(height: 6.h),
                DropdownButton<String>(
                  value: _searchSource,
                  onChanged: (val) => setState(() => _searchSource = val ?? "General"),
                  items: ["General", "Favoritos"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                ),
                SizedBox(height: 6.h),
                AppButton(
                label: "Abrir buscador",
                leading: const Icon(Icons.search),
                onPressed: _openSearchDialog,
                expanded: false, // o true si quieres que ocupe todo el ancho
              )

              ],
            ),
            isActive: _currentStep == 1,
            state: _selectedFoods.isEmpty ? StepState.indexed : StepState.complete,
          ),
          Step(
                title: const Text("Resumen"),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // a) Tipo de comida
                    Text("a) Tipo de comida: ${_mealType ?? '-'}"),
                    const SizedBox(height: 8),

                    // b) Alimentos elegidos
                    const Text("b) Alimentos elegidos:"),
                    const SizedBox(height: 6),
                    if (_selectedFoods.isEmpty)
                      const Text("- Ninguno -"),
                    ..._selectedFoods.map((food) {
                      final id = food['id']?.toString() ?? food['nombre'];
                      final name = food['nombre'] ?? '-';
                      final carbsController = _carbControllers[id];

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: (food['imagen'] != null && food['imagen'].toString().isNotEmpty)
                            ? Image.network(food['imagen'], width: 40.w, height: 40.h, fit: BoxFit.cover)
                            : const Icon(Icons.fastfood),
                        title: Text(name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Porción: ${food['porcion'] ?? '-'}"),
                            SizedBox(
                              width: 100,
                              child: TextField(
                                controller: carbsController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: "g carbs"),
                                onChanged: (_) => setState(() {}), // recalcula insulina dinámicamente
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => setState(() => _removeFood(food)),
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: 12),

                    // 
                    const Text("c) Insulina recomendada:"),
                    const SizedBox(height: 6),
                    TextField(
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      controller: _insulinController,
                      decoration: const InputDecoration(
                        labelText: "U",
                        border: OutlineInputBorder(),
                      ),
                      onTap: () {
                        _insulinController.selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: _insulinController.text.length,
                        );
                      },
                      onChanged: (val) {
                        final parsed = double.tryParse(val.replaceAll(',', '.'));
                        if (parsed != null) {
                          setState(() {
                            _userAdjustedInsulin = parsed;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 4),

                  
                    Text(
                          "Cálculo original: "
                          "(${_totalCarbs.toStringAsFixed(2)} / ${_carbsPorDosis.toStringAsFixed(2)}) "
                          "× ${_unidadesPorDosis.toStringAsFixed(2)} "
                          "= ${_insulinDose.toStringAsFixed(2)} U",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                isActive: _currentStep == 2,
                state: StepState.indexed,
              )

        ],
      ),
    );
  }

  void _openSearchDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (context, setDialogState) {
          List<Map<String, dynamic>> filteredFoods() {
            final source = _searchSource == "General" ? _allFoods : _favoriteFoods;
            final query = _searchQuery.trim().toLowerCase();

            return source.where((f) {
              final name = (f['nombre'] ?? '').toString().toLowerCase();
              final already = _selectedFoods.any((sel) {
                final selName = (sel['nombre'] ?? '').toString().toLowerCase();
                return selName == name;
              });
              if (already) return false;
              if (query.isEmpty) return true;
              return name.contains(query);
            }).take(30).toList();
          }

          return AlertDialog(
            title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Buscar en $_searchSource")]),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(hintText: "Buscar alimento...", prefixIcon: Icon(Icons.search)),
                    onChanged: (query) {
                      _searchQuery = query;
                      setDialogState(() {});
                    },
                  ),
                  SizedBox(height: 12.h),
                  Flexible(
                    child: Builder(builder: (ctx) {
                      final list = filteredFoods();
                      if (list.isEmpty) return const Center(child: Text("No se encontraron alimentos"));
                      return ListView.separated(
                        shrinkWrap: true,
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final food = list[i];
                          final name = food['nombre'] ?? '';
                          return ListTile(
                            leading: (food['imagen'] != null && food['imagen'].toString().isNotEmpty)
                                ? Image.network(food['imagen'], width: 40.w, height: 40.h, fit: BoxFit.cover)
                                : const Icon(Icons.fastfood, size: 40),
                            title: Text(name, style: TextStyle(fontSize: 14.sp)),
                            subtitle: Text("Carbs: ${_formatValue(food['carbohidratos'])}"),
                            onTap: () {
                              _toggleFood(food);
                              Navigator.of(dialogContext).pop();
                            },
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  String _formatValue(dynamic value) {
    if (value is Map && value.containsKey('cantidad') && value.containsKey('unidad')) {
      final num cantidad = value['cantidad'] ?? 0.0;
      final String unidad = value['unidad'] ?? '';
      return "${cantidad.toStringAsFixed(2)} $unidad";
    }
    if (value is num) return value.toStringAsFixed(2);
    return value?.toString() ?? '-';
  }

  void _toggleFood(Map<String, dynamic> food) {
    final id = food['id']?.toString() ?? food['nombre']?.toString() ?? UniqueKey().toString();
    if (_selectedFoods.any((f) => (f['id']?.toString() ?? f['nombre']) == id)) return;

    setState(() {
      final clonedFood = Map<String, dynamic>.from(food);

      double carbsValue = 0.0;
      final carbs = clonedFood['carbohidratos'];
      if (carbs is Map && carbs.containsKey('cantidad')) {
        final num cantidad = carbs['cantidad'] ?? 0.0;
        carbsValue = cantidad.toDouble();
      } else if (carbs is num) {
        carbsValue = carbs.toDouble();
      } else if (carbs is String) {
        carbsValue = double.tryParse(carbs.replaceAll(',', '.')) ?? 0.0;
      }

      clonedFood['id'] = id;

      _selectedFoods.add(clonedFood);

      _carbControllers[clonedFood['id']] = TextEditingController(text: carbsValue.toStringAsFixed(2));

      _portionControllers[clonedFood['id']] = TextEditingController(text: clonedFood['porcion']?.toString() ?? '');
    });
  }

  void _removeFood(Map<String, dynamic> food) {
    final id = food['id']?.toString() ?? food['nombre']?.toString();
    setState(() {
      _selectedFoods.removeWhere((f) => (f['id']?.toString() ?? f['nombre']) == id);
      _carbControllers[id]?.dispose();
      _portionControllers[id]?.dispose();
      _carbControllers.remove(id);
      _portionControllers.remove(id);
    });
  }

  double get _totalCarbs {
    double total = 0.0;
    for (var f in _selectedFoods) {
      final id = f['id']?.toString() ?? f['nombre'];
      final controller = _carbControllers[id];
      if (controller != null) {
        total += double.tryParse(controller.text) ?? 0.0;
      }
    }
    return total;
  }

  double get _insulinDose {
  if (_carbsPorDosis <= 0 || _unidadesPorDosis <= 0) return 0;
  return (_totalCarbs / _carbsPorDosis) * _unidadesPorDosis;
}


}
