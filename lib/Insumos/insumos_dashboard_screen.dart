import 'package:flutter/material.dart';
import 'package:insubite_new/Insumos/insumos_report_screen.dart';
import 'package:insubite_new/Insumos/insumos_stock_screen.dart';
import 'package:insubite_new/design_system/cards/list_nav_card.dart';
import 'insumos_screen.dart';

class InsumosDashboardScreen extends StatelessWidget {
  const InsumosDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insumos'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// ➕ Registrar insumo
            ListNavCard(
              icon: Icons.add_box_outlined,
              title: 'Registrar insumo',
              subtitle: 'Carga de retiros y consumos',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const InsumosScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            /// 📊 Historial
            ListNavCard(
              icon: Icons.history,
              title: 'Historial de insumos',
              subtitle: 'Ver consumos anteriores',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const InsumosHistoryScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            /// 📦 Stock / alertas
            ListNavCard(
            icon: Icons.inventory_2_outlined,
            title: 'Stock y alertas',
            subtitle: 'Control de stock disponible',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const InsumosStockScreen(),
                ),
              );
            },
          ),

          ],
        ),
      ),
    );
  }
}
