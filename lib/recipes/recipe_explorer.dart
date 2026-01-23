import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'recipe_catalog_screen.dart';
import '../design_system/cards/list_nav_card.dart';

class RecipeExplorerScreen extends StatelessWidget {
  const RecipeExplorerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (_, _) => Scaffold(
        appBar: AppBar(
          title: const Text("Explorador de recetas"),
        ),
        body: Padding(
          padding: EdgeInsets.all(16.w),
          child: ListView(
            children: [
              SizedBox(height: 12.h),

              ListNavCard(
                icon: Icons.restaurant_menu, // ICONO ORIGINAL ✔
                title: "Catálogo de recetas",
                subtitle: "Explora todas tus recetas disponibles",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RecipeCatalogScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
