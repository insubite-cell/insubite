import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:provider/provider.dart';
import 'primary_users/register_screen.dart';
import 'primary_users/firebase_options.dart';
import 'design_system/theme/app_theme.dart';
import 'session_resolver_screen.dart';
import 'package:flutter/foundation.dart';



// Pantallas principales
import 'primary_users/dashboard_screen.dart';
import 'primary_users/welcome_screen.dart';
import 'primary_users/login_form_screen.dart';
import 'primary_users/login_welcome_screen.dart';

// Perfil
import 'profile/profile_screen.dart';
import 'profile/medical_data_screen.dart';
import 'sensor_bomba/glucose_device_screen.dart';
import 'profile/shared_screen.dart';
import 'Insumos/insumos_screen.dart';

// Reportes
import 'static/reports_explorer_screen.dart';
import 'static/report/reports_home_screen.dart';
import 'static/report/history_report_screen.dart';
import 'static/report/insulin_report_screen.dart';
import 'static/report_info_screen.dart';
import 'Insumos/insumos_report_screen.dart';

// Dashboards
import 'static/dashbord/dashbord_nutrientes_screen.dart';
import 'static/dashbord/static_dashbord_screen.dart';

// Food
import 'group_food/food_explorer_screen.dart';
import 'group_food/food_calculator/food_calculator_screen.dart' as food_calculator;
import 'group_food/food/food_manager_screen.dart' as food_manager;
import 'group_food/food/food_favorite.dart';

// Recetas
import 'recipes/recipe_explorer.dart';

// 🌙 Tema oscuro
final temaNotifier = ValueNotifier<bool>(false);

/// =======================================================
/// SESSION PROVIDER (CIERRE FORZADO A LOS 2 MINUTOS)
/// =======================================================
class SessionProvider extends ChangeNotifier with WidgetsBindingObserver {
  static const Duration _timeout = Duration(minutes: 2);
  static const String _lastActivityKey = 'last_activity';

  Timer? _timer;

  SessionProvider() {
    WidgetsBinding.instance.addObserver(this);
    _saveActivity();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(_timeout, _logout);
  }

  Future<void> resetTimer() async {
    _startTimer();
    await _saveActivity();
  }

  Future<void> _saveActivity() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt(
      _lastActivityKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> _checkExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_lastActivityKey);

    if (last == null) return;

    final lastActivity = DateTime.fromMillisecondsSinceEpoch(last);
    final diff = DateTime.now().difference(lastActivity);

    if (diff >= _timeout) {
      _logout();
    }
  }

  void _logout() {
    FirebaseAuth.instance.signOut();
  }

  /// 🔥 CLAVE ABSOLUTA: cuando vuelve al foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkExpired();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }
}

/// =======================================================
/// MAIN
/// =======================================================



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔹 Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) {
      rethrow;
    }
  }

await FirebaseAppCheck.instance.activate(
  // ignore: deprecated_member_use
  androidProvider: kDebugMode
      ? AndroidProvider.debug  
      : AndroidProvider.playIntegrity,

);

  // 🔹 DEBUG: imprimir token de App Check
  try {
    final token = await FirebaseAppCheck.instance.getToken(true);
    debugPrint('🔥 DEBUG APP CHECK TOKEN: $token');
  } catch (e) {
    debugPrint('❌ ERROR getting App Check token: $e');
  }

  // 🔹 Tema: mantener tu lógica original
  final prefs = await SharedPreferences.getInstance();
  temaNotifier.value = prefs.getBool('tema_oscuro') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionProvider()),
      ],
      child: const MyApp(),
    ),
  );
}





/// =======================================================
/// APP
/// =======================================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionProvider =
        Provider.of<SessionProvider>(context, listen: false);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: sessionProvider.resetTimer,
      onPanDown: (_) => sessionProvider.resetTimer(),
      child: ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, _) {
          return ValueListenableBuilder<bool>(
            valueListenable: temaNotifier,
            builder: (context, isDark, _) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'Insubite',
                theme: AppTheme.light(),
                darkTheme: AppTheme.dark(),
                themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
                home: StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasData) {
                    return const SessionResolverScreen();
                  }

                  return const WelcomeScreen();
                },
              ),

                routes: {
                  '/welcome': (_) => const WelcomeScreen(),
                  '/login': (_) => const LoginFormScreen(),
                  '/register': (_) => const RegisterScreen(),
                  '/loginWelcome': (_) => const LoginWelcomeScreen(),
                  '/dashboard': (_) => DashboardScreen(principalUid: ''),

                  '/profile': (_) => const ProfileScreen(),
                  '/medical': (_) => const MedicalDataScreen(),
                  '/insumos': (_) => const InsumosScreen(),
                  '/shared_reports': (_) => const SharedScreen(),
                  '/glucose_device': (_) =>
                      const GlucoseDeviceScreen(),

                  '/report': (_) => const ReportsExplorerScreen(),
                  '/report_home': (_) => const ReportsHomeScreen(),
                  '/report_info': (_) => const ReportesInfoScreen(),
                  '/history_report': (_) =>
                      const HistoryReportScreen(),
                  '/insulin_report': (_) =>
                      const InsulinReportScreen(),
                  '/insumos_reportes': (_) =>
                      const InsumosHistoryScreen(),

                  '/dashbord_nutrientes': (_) =>
                      const DashboardNutrientesScreen(),
                  '/static_dashbord': (_) =>
                      const StaticDashbordScreen(),

                  '/food_explorer': (_) =>
                      const DashboardScreenFood(),
                  '/calculator': (_) =>
                      const food_calculator.FoodCalculatorScreen(),
                  '/food_manager': (_) =>
                      food_manager.FoodManagerScreen(),
                  '/favoritos': (_) =>
                      const FavoriteFoodsScreen(),

                  '/recipes_explorer': (_) =>
                      const RecipeExplorerScreen(),
                },
              );
            },
          );
        },
      ),
    );
  }
}
