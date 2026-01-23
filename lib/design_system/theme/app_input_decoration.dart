import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

InputDecoration appInputDecoration({
  required String label,
}) {
  return InputDecoration(
    labelText: label,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
    ),
    contentPadding: EdgeInsets.symmetric(
      horizontal: 12.w,
      vertical: 12.h,
    ),
  );
}
