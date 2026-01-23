import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../design_system/calendar/app_range_calendar.dart';

class HistoryReportScreen extends StatefulWidget {
  const HistoryReportScreen({super.key});

  @override
  State<HistoryReportScreen> createState() => _HistoryReportScreenState();
}

class _HistoryReportScreenState extends State<HistoryReportScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  bool _loading = true;
  DateTime _from = DateTime.now().subtract(const Duration(days: 7));
  DateTime _to = DateTime.now();

  String? _principalUid;
  double _totalCarbs = 0;
  Map<String, double> _byMeal = {};
  Map<String, List<Map<String, dynamic>>> _topByMeal = {};

  String _selectedMeal = 'todos';
  final List<String> _mealOptions = ['todos', 'desayuno', 'almuerzo', 'merienda', 'cena'];

  final Map<String, IconData> _mealIcons = {
    'desayuno': Icons.free_breakfast,
    'almuerzo': Icons.lunch_dining,
    'merienda': Icons.icecream,
    'cena': Icons.dinner_dining,
  };

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('usuarios').doc(user.uid).get();
    _principalUid = doc.data()?['lastValidated']?['principalUid'] ?? user.uid;

    _loadData();
  }

  Future<void> _loadData() async {
    if (_principalUid == null) return;
    setState(() => _loading = true);

    // Limpiar datos previos
    _byMeal.clear();
    _topByMeal.clear();
    _totalCarbs = 0;

    // 1️⃣ Traer cálculos agregados para carbohidratos totales y por comida
    final calcSnap = await _firestore
        .collection('usuarios/$_principalUid/calculos_agregados')
        .where('fecha', isGreaterThanOrEqualTo: _from.toIso8601String())
        .where('fecha', isLessThanOrEqualTo: _to.toIso8601String())
        .get();

    double total = 0;
    Map<String, double> mealsCarbs = {};

    for (final doc in calcSnap.docs) {
      final porComida = Map<String, dynamic>.from(doc['porComida'] ?? {});
      porComida.forEach((meal, data) {
        final carbs = (data['carbs'] as num?)?.toDouble() ?? 0;

        // Solo sumar si es la comida seleccionada (o todas para "todos")
        if (_selectedMeal == 'todos' || _selectedMeal == meal) {
          mealsCarbs[meal] = (mealsCarbs[meal] ?? 0) + carbs;
          total += carbs;
        }
      });
    }

    // 2️⃣ Traer alimentos para top 5
    final foodSnap = await _firestore
        .collection('usuarios/$_principalUid/alimentos')
        .where('fecha', isGreaterThanOrEqualTo: _from.toIso8601String())
        .where('fecha', isLessThanOrEqualTo: _to.toIso8601String())
        .get();

    Map<String, Map<String, int>> foodsByMeal = {};

    for (final doc in foodSnap.docs) {
      final porComida = Map<String, dynamic>.from(doc['porComida'] ?? {});

      porComida.forEach((meal, alimentosData) {
        // Solo contar si hay un filtro específico
        if (_selectedMeal != 'todos' && _selectedMeal != meal) return;

        final alimentos = List<Map<String, dynamic>>.from(alimentosData);
        for (final f in alimentos) {
          final name = f['nombre'] ?? '-';
          foodsByMeal[meal] ??= {};
          foodsByMeal[meal]![name] = (foodsByMeal[meal]![name] ?? 0) + 1;
        }
      });
    }

    Map<String, List<Map<String, dynamic>>> topFoodsByMeal = {};
    foodsByMeal.forEach((meal, foodMap) {
      final list = foodMap.entries
          .map((e) => {'nombre': e.key, 'count': e.value})
          .toList();
      list.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
      topFoodsByMeal[meal] = list.take(5).toList();
    });

    setState(() {
      _totalCarbs = total;
      _byMeal = mealsCarbs;
      _topByMeal = topFoodsByMeal;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Solo mostrar comidas filtradas
    List<String> mealsToShow = _selectedMeal == 'todos' ? [] : [_selectedMeal];

    return Scaffold(
      appBar: AppBar(title: const Text("Historial de comidas")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16.w),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                          _loadData();
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
                          _loadData();
                        }
                      },
                    ),
                    SizedBox(height: 16.h),

                    // Filtro por tipo de comida
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: DropdownButton<String>(
                        value: _selectedMeal,
                        items: _mealOptions
                            .map((m) => DropdownMenuItem(
                                  value: m,
                                  child: Text(m.toUpperCase()),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _selectedMeal = v);
                            _loadData();
                          }
                        },
                      ),
                    ),

                    // Total carbohidratos
                    Card(
                      child: ListTile(
                        leading:
                            const Icon(Icons.bar_chart, color: Colors.blue),
                        title: const Text("Total carbohidratos"),
                        trailing: Text(
                          "${_totalCarbs.toStringAsFixed(2)} g",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Cards por comida y top 5 alimentos
                    ...mealsToShow.map((meal) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            child: ListTile(
                              leading:
                                  Icon(_mealIcons[meal] ?? Icons.restaurant),
                              title: Text(meal.toUpperCase()),
                              trailing: Text(
                                "${_byMeal[meal]?.toStringAsFixed(2) ?? 0} g",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          if (_topByMeal[meal] != null)
                            Padding(
                              padding: EdgeInsets.only(
                                  left: 40.w, top: 4.h, bottom: 8.h),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _topByMeal[meal]!
                                    .map((f) =>
                                        Text("${f['nombre']} x${f['count']}"))
                                    .toList(),
                              ),
                            ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
    );
  }
}
