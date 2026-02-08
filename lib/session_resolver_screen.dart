import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'primary_users/dashboard_screen.dart';
import 'primary_users/welcome_screen.dart';

class SessionResolverScreen extends StatelessWidget {
  const SessionResolverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const WelcomeScreen();
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const WelcomeScreen();
        }

        final data =
            snapshot.data!.data() as Map<String, dynamic>?;

        final principalUid =
            data?['lastValidated']?['principalUid'] ?? user.uid;

        return DashboardScreen(principalUid: principalUid);
      },
    );
  }
}
