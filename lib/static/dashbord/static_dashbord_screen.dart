import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../design_system/calendar/app_range_calendar.dart';
import '../../service/dashbord_service.dart';
import '../../service/user_session_service.dart';

class StaticDashbordScreen extends StatefulWidget {
  const StaticDashbordScreen({super.key});

  @override
  State<StaticDashbordScreen> createState() => _StaticDashbordScreenState();
}

class _StaticDashbordScreenState extends State<StaticDashbordScreen> {
  final DashboardService service = DashboardService();
  final UserSessionService sessionService = UserSessionService();

  List<Map<String, dynamic>> data = [];

  DateTime _from = DateTime.now().subtract(const Duration(days: 7));
  DateTime _to = DateTime.now();

  final TooltipBehavior _tooltipBehavior =
      TooltipBehavior(enable: true);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = await sessionService.getEffectiveUid();
    final result = await service.getTendencias(
      start: _from,
      end: _to,
      uid: uid,
    );

    if (!mounted) return;
    setState(() => data = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard Carbohidratos")),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: SingleChildScrollView(
          child: Column(
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
                  if (d != null && mounted) {
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
                  if (d != null && mounted) {
                    setState(() => _to = d);
                    _loadData();
                  }
                },
              ),
              SizedBox(height: 24.h),
              SizedBox(
                height: 320.h,
                child: SfCartesianChart(
                  tooltipBehavior: _tooltipBehavior,
                  primaryXAxis: DateTimeAxis(),
                  series: [
                    LineSeries<Map<String, dynamic>, DateTime>(
                      name: 'Carbohidratos',
                      dataSource: data,
                      xValueMapper: (d, _) => d['fecha'],
                      yValueMapper: (d, _) =>
                          (d['carbohidratos'] as num).toDouble(),
                    ),
                    LineSeries<Map<String, dynamic>, DateTime>(
                      name: 'Insulina',
                      dataSource: data,
                      xValueMapper: (d, _) => d['fecha'],
                      yValueMapper: (d, _) =>
                          (d['insulina'] as num).toDouble(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
