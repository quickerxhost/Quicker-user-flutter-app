import 'package:flutter/material.dart';

/// Color tokens extracted 1:1 from the Stitch design source
/// (`quickerx_premium_marketplace/DESIGN.md`). Do not alter these values —
/// they are the approved brand palette.
abstract final class AppColors {
  // Surfaces
  static const surface = Color(0xFFF8F9FA);
  static const surfaceDim = Color(0xFFD9DADB);
  static const surfaceBright = Color(0xFFF8F9FA);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF3F4F5);
  static const surfaceContainer = Color(0xFFEDEEEF);
  static const surfaceContainerHigh = Color(0xFFE7E8E9);
  static const surfaceContainerHighest = Color(0xFFE1E3E4);
  static const surfaceVariant = Color(0xFFE1E3E4);

  static const onSurface = Color(0xFF191C1D);
  static const onSurfaceVariant = Color(0xFF494455);
  static const inverseSurface = Color(0xFF2E3132);
  static const inverseOnSurface = Color(0xFFF0F1F2);

  static const outline = Color(0xFF7A7486);
  static const outlineVariant = Color(0xFFCBC3D7);
  static const surfaceTint = Color(0xFF6C37DF);

  // Primary (Deep Purple)
  static const primary = Color(0xFF4400A8);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF5D21D0);
  static const onPrimaryContainer = Color(0xFFCBB8FF);
  static const inversePrimary = Color(0xFFCFBCFF);
  static const primaryFixed = Color(0xFFE9DDFF);
  static const primaryFixedDim = Color(0xFFCFBCFF);
  static const onPrimaryFixed = Color(0xFF22005D);
  static const onPrimaryFixedVariant = Color(0xFF540BC7);

  // Secondary (Vibrant Orange)
  static const secondary = Color(0xFFA04100);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFFE6B00);
  static const onSecondaryContainer = Color(0xFF572000);
  static const secondaryFixed = Color(0xFFFFDBCC);
  static const secondaryFixedDim = Color(0xFFFFB693);
  static const onSecondaryFixed = Color(0xFF351000);
  static const onSecondaryFixedVariant = Color(0xFF7A3000);

  // Tertiary
  static const tertiary = Color(0xFF393939);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFF505050);
  static const onTertiaryContainer = Color(0xFFC4C2C2);
  static const tertiaryFixed = Color(0xFFE5E2E1);
  static const tertiaryFixedDim = Color(0xFFC8C6C5);
  static const onTertiaryFixed = Color(0xFF1B1C1C);
  static const onTertiaryFixedVariant = Color(0xFF474746);

  // Error
  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  // Background
  static const background = Color(0xFFF8F9FA);
  static const onBackground = Color(0xFF191C1D);

  // Ambient shadows (from DESIGN.md "Elevation & Depth")
  static const shadowLevel1 = Color(0x0A000000); // rgba(0,0,0,0.04)
  static const shadowLevel2 = Color(0x1F5D21D0); // rgba(93,33,208,0.12)
}
