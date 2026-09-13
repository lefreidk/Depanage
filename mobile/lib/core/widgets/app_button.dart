import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, outline, ghost, danger }

/// زر موحّد لكل التطبيق، يدعم:
/// - حالة تحميل مدمجة (loading) بدون الحاجة لإدارة CircularProgressIndicator يدوياً في كل شاشة
/// - أيقونة اختيارية
/// - أربع أنماط بصرية (أساسي / تمييز / محدد / شفاف)
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = isLoading || onPressed == null;

    final child = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: variant == AppButtonVariant.outline || variant == AppButtonVariant.ghost
                  ? AppColors.primary
                  : Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: AppSpacing.sm)],
              Text(label),
            ],
          );

    Widget button;
    switch (variant) {
      case AppButtonVariant.primary:
        button = ElevatedButton(onPressed: disabled ? null : onPressed, child: child);
        break;
      case AppButtonVariant.secondary:
        button = ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
          onPressed: disabled ? null : onPressed,
          child: child,
        );
        break;
      case AppButtonVariant.outline:
        button = OutlinedButton(onPressed: disabled ? null : onPressed, child: child);
        break;
      case AppButtonVariant.ghost:
        button = TextButton(
          style: TextButton.styleFrom(minimumSize: const Size.fromHeight(54)),
          onPressed: disabled ? null : onPressed,
          child: child,
        );
        break;
      case AppButtonVariant.danger:
        button = ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: disabled ? null : onPressed,
          child: child,
        );
        break;
    }

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// زر دائري عائم مصغّر يُستخدم فوق الخرائط (قائمة، تكبير، موقعي...)
class AppCircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? iconColor;

  const AppCircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: backgroundColor ?? scheme.surface,
      shape: const CircleBorder(),
      elevation: AppElevation.medium,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: iconColor ?? AppColors.primary, size: 22),
        ),
      ),
    );
  }
}
