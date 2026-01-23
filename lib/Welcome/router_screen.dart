// lib/service/router_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Importá tus pantallas
import '../Welcome/welcome_screen.dart';
import '../primary_users/dashboard_screen.dart';
import '../secondary_users/secondary_dashboard_screen.dart';

class RouterScreen extends StatefulWidget {
  const RouterScreen({super.key});

  @override
  State<RouterScreen> createState() => _RouterScreenState();
}

class _RouterScreenState extends State<RouterScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserAndNavigate();
  }

  Future<void> _checkUserAndNavigate() async {
    await Future.delayed(const Duration(seconds: 1)); // leve splash
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // 🔹 Usuario no logueado → va a Welcome
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        // 🔹 No hay registro → tratamos como principal por defecto
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DashboardScreen(principalUid: '',)),
        );
        return;
      }

      final data = doc.data() ?? {};
      final isSecondary = data['isSecondary'] == true;
      final principalUid = data['principalUid'];

      if (isSecondary && principalUid != null) {
        // 🔹 Usuario secundario
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SecondaryDashboardScreen(
              principalUid: principalUid,
              principalEmail: data['principalEmail'] ?? '',
            ),
          ),
        );
      } else {
        // 🔹 Usuario principal
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DashboardScreen(principalUid: '',)),
        );
      }
    } catch (e) {
      debugPrint('Error al obtener usuario: $e');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
