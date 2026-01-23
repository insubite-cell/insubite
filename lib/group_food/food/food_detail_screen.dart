import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FoodDetailScreen extends StatelessWidget {
  final Map<String, dynamic> producto;

  const FoodDetailScreen({super.key, required this.producto});

  @override
  Widget build(BuildContext context) {
    final nutriments = producto["nutriments"] ?? {};
    final imageUrl = producto["image_url"] ?? producto["image_front_url"];

    // Nutrientes más importantes
    final nutrientesClaves = {
      "energy-kcal_100g": "Energía (kcal)",
      "carbohydrates_100g": "Carbohidratos (g)",
      "sugars_100g": "Azúcares (g)",
      "fat_100g": "Grasas (g)",
      "saturated-fat_100g": "Grasas saturadas (g)",
      "proteins_100g": "Proteínas (g)",
      "salt_100g": "Sal (g)",
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(
          producto["product_name"] ?? "Detalle del producto",
          style: TextStyle(fontSize: 18.sp),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen grande
            Center(
              child: imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: Image.network(
                        imageUrl,
                        width: 200.w,
                        height: 200.h,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.fastfood, size: 80.sp),
                      ),
                    )
                  : Icon(Icons.fastfood, size: 80.sp),
            ),
            SizedBox(height: 20.h),

            // Nombre del producto
            Text(
              producto["product_name"] ?? "Producto sin nombre",
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20.h),

            // Tabla nutricional
            Text(
              "Información nutricional (por 100g):",
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12.h),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r)),
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  children: nutrientesClaves.entries.map<Widget>((entry) {
                    final valor = nutriments[entry.key];
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 6.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              entry.value,
                              style: TextStyle(fontSize: 14.sp),
                            ),
                          ),
                          Text(
                            valor != null ? valor.toString() : "-",
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
