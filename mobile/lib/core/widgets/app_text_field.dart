import 'package:flutter/material.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? initialValue;
  final bool readOnly;
  final bool obscureText;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final int maxLines;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.initialValue,
    this.readOnly = false,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffix,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm, right: 4),
          child: Text(label, style: AppTextStyles.bodyMedium(colors.textPrimary)),
        ),
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          readOnly: readOnly,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          style: AppTextStyles.bodyLarge(colors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: colors.textSecondary, size: 21)
                : null,
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}
