import 'package:flutter/material.dart';

class AppDateField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const AppDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        child: Text(value),
      ),
    );
  }
}
