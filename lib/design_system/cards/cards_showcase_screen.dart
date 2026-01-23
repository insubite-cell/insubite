import 'package:flutter/material.dart';
import '../cards/metric_card.dart';
import '../cards/icon_card.dart';
import '../cards/app_card.dart';

class CardsShowcaseScreen extends StatelessWidget {
  const CardsShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tarjetas – Design System')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('Métricas', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            Row(
              children: const [
                Expanded(
                  child: MetricCard(
                    label: 'Carbohidratos',
                    value: '120 g',
                    color: Colors.orange,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: MetricCard(
                    label: 'Insulina',
                    value: '8 U',
                    color: Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Text('Tarjeta simple', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            AppCard(
              child: Text(
                'Esta es una tarjeta simple para contenido libre',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),

            const SizedBox(height: 24),

            Text('Tarjetas con ícono', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                IconCard(
                  icon: Icons.food_bank,
                  title: 'Alimentos',
                  subtitle: 'Explorar',
                  onTap: () {},
                ),
                IconCard(
                  icon: Icons.camera_alt,
                  title: 'Foto',
                  subtitle: 'Tomar imagen',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
