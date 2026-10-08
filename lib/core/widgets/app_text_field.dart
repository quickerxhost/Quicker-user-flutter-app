import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.prefixWidget,
    this.suffixWidget,
    this.validator,
    this.onChanged,
    this.autofocus = false,
    this.textInputAction,
    this.maxLength,
    this.inputFormatters,
    this.errorText,
  });

  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? prefixWidget;
  final Widget? suffixWidget;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      onChanged: onChanged,
      autofocus: autofocus,
      textInputAction: textInputAction,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      style: AppTypography.bodyMd(color: AppColors.onSurface),
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        errorText: errorText,
        counterText: '',
        prefixIcon: prefixWidget ??
            (prefixIcon != null
                ? Icon(prefixIcon, color: AppColors.onSurfaceVariant)
                : null),
        suffixIcon: suffixWidget,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.base),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
