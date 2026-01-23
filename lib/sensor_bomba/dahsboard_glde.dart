import 'package:flutter/material.dart';
import 'insulin_pump_screen.dart';
import 'package:insubite_new/design_system/cards/list_nav_card.dart';
import 'package:insubite_new/sensor_bomba/glucose_device_screen.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispositivos'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListNavCard(
              icon: Icons.sensors_outlined,
              title: 'Sensores',
              subtitle: 'Gestión de sensores de glucosa',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GlucoseDeviceScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
           ListNavCard(
  icon: Icons.medical_services_outlined,
  title: 'Bombas de insulina',
  subtitle: 'Gestión de bombas de insulina',
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const InsulinPumpScreen(),
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
