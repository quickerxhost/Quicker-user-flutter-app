import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Type scale extracted from the Stitch DESIGN.md `typography` block.
/// Font family is Inter throughout, loaded via google_fonts so no manual
/// font-asset bundling is required.
abstract final class AppTypography {
  static TextStyle _inter({
    required double size,
    required FontWeight weight,
    required double height,
    double letterSpacing = 0,
    Color color = AppColors.onSurface,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      height: height / size,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  /// display-lg: 48/56, weight 800, -0.02em
  static TextStyle displayLg({Color? color}) => _inter(
        size: 48,
        weight: FontWeight.w800,
        height: 56,
        letterSpacing: -0.02 * 48,
        color: color ?? AppColors.onSurface,
      );

  /// headline-lg: 32/40, weight 700, -0.01em
  static TextStyle headlineLg({Color? color}) => _inter(
        size: 32,
        weight: FontWeight.w700,
        height: 40,
        letterSpacing: -0.01 * 32,
        color: color ?? AppColors.onSurface,
      );

  /// headline-lg-mobile: 28/36, weight 700
  static TextStyle headlineLgMobile({Color? color}) => _inter(
        size: 28,
        weight: FontWeight.w700,
        height: 36,
        color: color ?? AppColors.onSurface,
      );

  /// title-lg: 22/28, weight 600
  static TextStyle titleLg({Color? color}) => _inter(
        size: 22,
        weight: FontWeight.w600,
        height: 28,
        color: color ?? AppColors.onSurface,
      );

  /// body-lg: 18/26, weight 400 (base body size for senior legibility)
  static TextStyle bodyLg({Color? color}) => _inter(
        size: 18,
        weight: FontWeight.w400,
        height: 26,
        color: color ?? AppColors.onSurface,
      );

  /// body-md: 16/24, weight 400
  static TextStyle bodyMd({Color? color}) => _inter(
        size: 16,
        weight: FontWeight.w400,
        height: 24,
        color: color ?? AppColors.onSurface,
      );

  /// label-lg: 14/20, weight 600, 0.1px
  static TextStyle labelLg({Color? color}) => _inter(
        size: 14,
        weight: FontWeight.w600,
        height: 20,
        letterSpacing: 0.1,
        color: color ?? AppColors.onSurface,
      );
}
