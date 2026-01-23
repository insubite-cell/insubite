import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../design_system/calendar/app_range_calendar.dart';
import '../../service/dashbord_service.dart';
import '../../service/user_session_service.dart';

class DashboardNutrientesScreen extends StatefulWidget {
  const DashboardNutrientesScreen({super.key});

  @override
  State<DashboardNutrientesScreen> createState() =>
      _DashboardNutrientesScreenState();
}

class _DashboardNutrientesScreenState
    extends State<DashboardNutrientesScreen> {
  final DashboardService service = DashboardService();
  final UserSessionService sessionService = UserSessionService();

  Map<String, double> nutrientes = {};

  DateTime _from = DateTime.now().subtract(const Duration(days: 7));
  DateTime _to = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadNutrientes();
  }

  Future<void> _loadNutrientes() async {
    final effectiveUid = await sessionService.getEffectiveUid();

    final stats = await service.getNutrientesStats(
      start: _from,
      end: _to,
      uid: effectiveUid,
    );

    if (!mounted) return;

    setState(() {
      nutrientes = stats.map(
        (k, v) => MapEntry(k, (v * 100).roundToDouble() / 100),
      );
    });
  }

  String _prettifyName(String raw) =>
      raw.split('_').map((e) => '${e[0].toUpperCase()}${e.substring(1)}').join(' ');

  @override
  Widget build(BuildContext context) {
    final total = nutrientes.values.fold<double>(0, (a, b) => a + b);

    final chartData = nutrientes.entries
        .map((e) => _ChartData(
              _prettifyName(e.key),
              e.value,
              total > 0 ? (e.value / total) * 100 : 0,
            ))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Nutrientes Específicos")),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: SingleChildScrollView(
          child: Column(
            children: [
              AppRangeCalendar(
                startDate: _from,
                endDate: _to,
                onPickStart: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _from,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null && mounted) {
                    setState(() => _from = date);
                    _loadNutrientes();
                  }
                },
                onPickEnd: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _to,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null && mounted) {
                    setState(() => _to = date);
                    _loadNutrientes();
                  }
                },
              ),
              SizedBox(height: 24.h),

              // 🔵 Gráfico de torta
              SizedBox(
                height: 400.h,
                child: SfCircularChart(
                  legend: Legend(
                    isVisible: true,
                    position: LegendPosition.bottom,
                  ),
                  series: <CircularSeries<_ChartData, String>>[
                    PieSeries<_ChartData, String>(
                      dataSource: chartData,
                      xValueMapper: (d, _) => d.label,
                      yValueMapper: (d, _) => d.value,
                      dataLabelMapper: (d, _) =>
                          "${d.label}: ${d.value.toStringAsFixed(2)}",
                      dataLabelSettings:
                          const DataLabelSettings(isVisible: true),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // 📝 Lista de nutrientes para mejor lectura
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Detalle de Nutrientes",
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Divider(),
                      ...chartData.map((nutr) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                nutr.label,
                                style: TextStyle(fontSize: 16.sp),
                              ),
                              Text(
                                "${nutr.value.toStringAsFixed(2)} g (${nutr.percent.toStringAsFixed(1)}%)",
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartData {
  final String label;
  final double value;
  final double percent;

  _ChartData(this.label, this.value, this.percent);
}
