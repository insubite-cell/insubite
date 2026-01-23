import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
 import 'package:firebase_app_check/firebase_app_check.dart';

import 'primary_users/firebase_options.dart';
import 'design_system/theme/app_theme.dart';

// Pantallas principales
import 'primary_users/dashboard_screen.dart';
import 'primary_users/welcome_screen.dart';
import 'primary_users/login_form_screen.dart';
import 'primary_users/login_welcome_screen.dart';
import 'primary_users/register_screen.dart';

// Perfil
import 'profile/profile_screen.dart';
import 'profile/medical_data_screen.dart';
import 'profile/glucose_device_screen.dart';
import 'profile/shared_screen.dart';
import 'Insumos/insumos_screen.dart';

// Reportes
import 'static/reports_explorer_screen.dart';
import 'static/report/reports_home_screen.dart';
import 'static/report/history_report_screen.dart';
import 'static/report/insulin_report_screen.dart';
import 'static/report_info_screen.dart';
import 'static/report/insumos_report_screen.dart';

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

final temaNotifier = ValueNotifier<bool>(false);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔹 Inicializa Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase inicializado');
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      debugPrint('Firebase ya estaba inicializado, continuando...');
    } else {
      rethrow;
    }
  }


await FirebaseAppCheck.instance.activate(
  providerAndroid: AndroidDebugProvider(),
);


// 🔹 Activar App Check para debug con token
// await FirebaseAppCheck.instance.activate(
//   providerAndroid: AndroidDebugProvider(
//     debugToken: '8743F78C-B8DF-4689-A5EF-37453A29A81B', // <- aquí tu token
//   ),
// );


  // 🔹 Obtener token de App Check y mostrarlo en consola
//   try {
//     final token = await FirebaseAppCheck.instance.getToken();
//     debugPrint('🔹 AppCheck Debug Token: $token');
//   } catch (e, st) {
//     debugPrint('❌ Error obteniendo token App Check: $e');
//     debugPrint('$st');
//   }

  // 🔹 Lee tema oscuro desde SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  temaNotifier.value = prefs.getBool('tema_oscuro') ?? false;

  // 🔹 Ejecuta la app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
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
                    return const DashboardScreen(principalUid: '');
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
                '/glucose_device': (_) => const GlucoseDeviceScreen(),

                '/report': (_) => const ReportsExplorerScreen(),
                '/report_home': (_) => const ReportsHomeScreen(),
                '/report_info': (_) => const ReportesInfoScreen(),
                '/history_report': (_) => const HistoryReportScreen(),
                '/insulin_report': (_) => const InsulinReportScreen(),
                '/insumos_reportes': (_) => const InsumosReportScreenSimple(),

                '/dashbord_nutrientes': (_) => const DashboardNutrientesScreen(),
                '/static_dashbord': (_) => const StaticDashbordScreen(),

                '/food_explorer': (_) => const DashboardScreenFood(),
                '/calculator': (_) => const food_calculator.FoodCalculatorScreen(),
                '/food_manager': (_) => food_manager.FoodManagerScreen(),
                '/food_favorite': (_) => const FavoriteFoodsScreen(principalUid: ''),

                '/recipes_explorer': (_) => const RecipeExplorerScreen(),
              },
            );
          },
        );
      },
    );
  }
}
