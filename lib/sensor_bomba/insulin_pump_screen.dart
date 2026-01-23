import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:insubite_new/design_system/inputs/app_text_field.dart';
import 'package:insubite_new/design_system/cards/app_card.dart';
import 'package:insubite_new/design_system/cards/list_nav_card.dart';

class InsulinPumpScreen extends StatefulWidget {
  const InsulinPumpScreen({super.key});

  @override
  State<InsulinPumpScreen> createState() => _InsulinPumpScreenState();
}

class _InsulinPumpScreenState extends State<InsulinPumpScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _serialController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bombas de Insulina'),
      ),
      body: Column(
        children: [
          /// FORMULARIO
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(12.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      controller: _brandController,
                      label: 'Marca',
                    ),
                    SizedBox(height: 12.h),
                    AppTextField(
                      controller: _modelController,
                      label: 'Modelo',
                    ),
                    SizedBox(height: 12.h),
                    AppTextField(
                      controller: _serialController,
                      label: 'Número de serie',
                    ),
                    SizedBox(height: 16.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          
                        },
                        child: const Text('Guardar bomba'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Divider(height: 1.h),

          /// LISTADO (mock)
          Expanded(
            flex: 3,
            child: ListView(
              padding: EdgeInsets.all(12.w),
              children: [
                AppCard(
                  child: ListNavCard(
                    icon: Icons.medical_services_outlined,
                    title: 'Medtronic',
                    subtitle: 'Modelo 780G • N° 123456',
                    onTap: () {},
                  ),
                ),
                SizedBox(height: 8.h),
                AppCard(
                  child: ListNavCard(
                    icon: Icons.medical_services_outlined,
                    title: 'Accu-Chek',
                    subtitle: 'Modelo Combo • N° 654321',
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
