import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insubite/design_system/buttons/app_button.dart';
import 'secondary_users_screen.dart';

class SharedScreen extends StatefulWidget {
  const SharedScreen({super.key});

  @override
  State<SharedScreen> createState() => _SharedScreen();
}

class _SharedScreen extends State<SharedScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String _shareCode = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingCode();
  }

  Future<void> _loadExistingCode() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final doc = await _firestore
        .collection("usuarios")
        .doc(uid)
        .collection("shared")
        .doc("info")
        .get();

    if (doc.exists && doc.data()?['shareCode'] != null) {
      setState(() {
        _shareCode = doc['shareCode'];
      });
    }
  }

  Future<void> _askGenerateCode() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Generar código"),
        content: const Text(
            "¿Querés generar un código para compartir tu información?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("No"),
          ),
          AppButton(
            label: "Sí",
            expanded: true,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);

    try {
      final ref = _firestore
          .collection("usuarios")
          .doc(uid)
          .collection("shared")
          .doc("info");

      final doc = await ref.get();

      if (!doc.exists || doc.data()?['shareCode'] == null) {
        final code = _generateShareCode();
        await ref.set({
          'shareCode': code,
          'createdAt': FieldValue.serverTimestamp(),
        });
        setState(() => _shareCode = code);
      } else {
        setState(() => _shareCode = doc['shareCode']);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _generateShareCode() {
    final random = Random();
    return List.generate(8, (_) => random.nextInt(10).toString()).join();
  }

  void _goToAdmin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SecondaryUsersScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, _) => Scaffold(
        appBar: AppBar(title: const Text("Compartir informes")),
        body: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Compartir mediante código",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20.h),

              if (_shareCode.isEmpty) ...[
                const Text(
                  "Aún no generaste un código de compartición.",
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20.h),
                AppButton(
                  label: "Generar código",
                  leading: const Icon(Icons.key),
                  expanded: true,
                  loading: _loading,
                  onPressed: _loading ? null : _askGenerateCode,
                ),
              ] else ...[
                SelectableText(
                  _shareCode,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 12.h),
                const Text(
                  "Copiá este código y envíaselo a la persona que quieras.",
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20.h),
                AppButton(
                  label: "Copiar código",
                  leading: const Icon(Icons.copy),
                  expanded: true,
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: _shareCode),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Código copiado")),
                    );
                  },
                ),
                SizedBox(height: 24.h),
                AppButton(
                  label: "Administrar accesos",
                  leading: const Icon(Icons.manage_accounts),
                  expanded: true,
                  selected: true,
                  onPressed: _goToAdmin,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
