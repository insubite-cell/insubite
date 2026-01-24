import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:insubite/design_system/buttons/app_button.dart';

class SecondaryUsersScreen extends StatelessWidget {
  const SecondaryUsersScreen({super.key});

  /* ================== ONLINE STATUS ================== */

  bool _isOnline(Timestamp? lastUpdate) {
    if (lastUpdate == null) return false;
    final diff = DateTime.now().difference(lastUpdate.toDate());
    return diff.inMinutes < 5;
  }

  String _lastSeenText(Timestamp? lastUpdate) {
    if (lastUpdate == null) return 'Nunca';

    final diff = DateTime.now().difference(lastUpdate.toDate());
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    return 'Hace ${diff.inDays} días';
  }

  /* ================== DISCONNECT ================== */

  Future<void> _disconnectUser(
    BuildContext context,
    String uid,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Desconectar usuario"),
        content: const Text(
          "¿Querés desconectar este usuario secundario?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar"),
          ),
          AppButton(
            label: "Desconectar",
            expanded: true,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .update({
      'lastValidated': FieldValue.delete(),
    });
  }

  /* ================== UI ================== */

  @override
  Widget build(BuildContext context) {
    final principalUid = FirebaseAuth.instance.currentUser!.uid;

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, _) => Scaffold(
        appBar: AppBar(title: const Text("Usuarios secundarios")),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('usuarios')
              .where(
                'lastValidated.principalUid',
                isEqualTo: principalUid,
              )
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final users = snapshot.data!.docs;

            if (users.isEmpty) {
              return const Center(
                child: Text("No hay usuarios conectados"),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final doc = users[index];
                final data = doc.data() as Map<String, dynamic>;

                final lastValidated =
                    data['lastValidated'] as Map<String, dynamic>?;

                final lastUpdate =
                    data['lastUpdate'] as Timestamp?;

                final online = _isOnline(lastUpdate);

                return Card(
                  margin: EdgeInsets.only(bottom: 12.h),
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lastValidated?['email'] ??
                              'Usuario secundario',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          online ? 'Conectado' : 'Inactivo',
                          style: TextStyle(
                            color:
                                online ? Colors.green : Colors.grey,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Último acceso: ${_lastSeenText(lastUpdate)}',
                          style: TextStyle(fontSize: 12.sp),
                        ),
                        SizedBox(height: 12.h),
                        AppButton(
                          label: "Desconectar",
                          outlined: true,
                          expanded: true,
                          onPressed: () =>
                              _disconnectUser(context, doc.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
