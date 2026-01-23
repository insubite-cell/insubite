import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool expanded;
  final bool selected;
  final bool outlined;
  final Widget? leading;

  /// 🔹 Soporte de carga (loading)
  final bool loading;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.expanded = false,
    this.selected = true,
    this.outlined = false,
    this.leading,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isOutlined = outlined;

    // Estilo del botón
    final buttonStyle = isOutlined
        ? OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            textStyle: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          )
        : ElevatedButton.styleFrom(
            elevation: selected ? 2 : 0,
            backgroundColor: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade200,
            foregroundColor: selected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
            padding: EdgeInsets.symmetric(vertical: 16.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            textStyle: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          );

    // Contenido del botón (loading o texto + icono)
    final child = loading
        ? SizedBox(
            height: 22.h,
            width: 22.h,
            child: CircularProgressIndicator(
              strokeWidth: 2.h,
              color: isOutlined
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white,
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                leading!,
                SizedBox(width: 8.w),
              ],
              Text(label),
            ],
          );

    // Botón final (Outlined o Elevated)
    final button = isOutlined
        ? OutlinedButton(
            onPressed: loading ? null : onPressed,
            style: buttonStyle,
            child: child,
          )
        : ElevatedButton(
            onPressed: loading ? null : onPressed,
            style: buttonStyle,
            child: child,
          );

    // Expandido si se requiere
    if (expanded) {
      return SizedBox(width: double.infinity, child: button);
    }

    return button;
  }
}
