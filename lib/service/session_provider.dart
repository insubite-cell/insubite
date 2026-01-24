import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SessionProvider extends ChangeNotifier {
  final Duration timeout;
  Timer? _inactivityTimer;

  SessionProvider({this.timeout = const Duration(minutes: 5)}) {
    _startTimer();
  }

  void _startTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(timeout, _logoutUser);
  }

  void resetTimer() {
    _startTimer();
  }

  void _logoutUser() {
    FirebaseAuth.instance.signOut();
    // También podés agregar navegación al login si querés
  }

  void disposeProvider() {
    _inactivityTimer?.cancel();
  }
}
