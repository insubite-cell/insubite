import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insubite/design_system/inputs/app_text_field.dart';

import '../design_system/buttons/app_button.dart';
import 'secondary_dashboard_screen.dart';

class ValidatePrincipalScreen extends StatefulWidget {
  const ValidatePrincipalScreen({super.key});

  @override
  State<ValidatePrincipalScreen> createState() =>
      _ValidatePrincipalScreenState();
}

class _ValidatePrincipalScreenState extends State<ValidatePrincipalScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codigoController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _loading = false;
  bool _validated = false;
  bool _saving = false;

  String _principalUid = '';
  String _principalEmail = '';

  Future<void> _validate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final email = _emailController.text.trim().toLowerCase();
      final codigo = _codigoController.text.trim();

      final querySnapshot = await _firestore
          .collection('usuarios')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('No se encontró ningún principal con email: $email'),
          ),
        );
        return;
      }

      final principalDoc = querySnapshot.docs.first;
      final principalUid = principalDoc.id;

      final infoDoc = await _firestore
          .collection('usuarios')
          .doc(principalUid)
          .collection('shared')
          .doc('info')
          .get();

      if (!infoDoc.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('No se encontró información compartida para este principal'),
          ),
        );
        return;
      }

      final data = infoDoc.data();
      final storedShareCode = data?['shareCode'] ?? '';

      if (storedShareCode != codigo) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('El código ingresado no coincide con el principal'),
          ),
        );
        return;
      }

      setState(() {
        _validated = true;
        _principalUid = principalUid;
        _principalEmail = email;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Código válido. Presione "Continuar" para seguir'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al validar: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _continuar() async {
    setState(() => _saving = true);

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw 'Usuario secundario no logueado';
      }

      final secondaryUid = currentUser.uid;

      await _firestore.collection('usuarios').doc(secondaryUid).set({
        'lastValidated': {
          'principalUid': _principalUid,
          'email': _principalEmail,
          'codigo': _codigoController.text.trim(),
          'timestamp': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SecondaryDashboardScreen(
            principalUid: _principalUid,
            principalEmail: _principalEmail,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al continuar: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codigoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, _) => Scaffold(
        appBar: AppBar(title: const Text('Validar Principal')),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 40.h),

                AppTextField(
                controller: _emailController,
                label: 'Email del principal',
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ingrese email' : null,
              ),


                SizedBox(height: 16.h),

                AppTextField(
                controller: _codigoController,
                label: 'Código del principal',
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ingrese código' : null,
              ),
                SizedBox(height: 28.h),

                AppButton(
                  label: _loading ? 'Validando...' : 'Validar',
                  expanded: true,
                  onPressed: _loading ? null : _validate,
                  leading: _loading
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),

                if (_validated) ...[
                  SizedBox(height: 16.h),
                  AppButton(
                    label: _saving ? 'Guardando...' : 'Continuar',
                    expanded: true,
                    onPressed: _saving ? null : _continuar,
                    leading: _saving
                        ? SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
