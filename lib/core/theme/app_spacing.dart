/// Spacing tokens from DESIGN.md `spacing` block. 8px linear scale with
/// 20px outer margins on mobile ("breathing room" over standard 16px).
abstract final class AppSpacing {
  static const double base = 8;
  static const double marginMobile = 20;
  static const double marginDesktop = 40;
  static const double gutter = 16;
  static const double sectionGap = 32;
  static const double touchTargetMin = 48;

  // Convenience multiples of the 8px base scale.
  static const double xs = 4;
  static const double sm = base; // 8
  static const double md = base * 2; // 16
  static const double lg = base * 3; // 24
  static const double xl = base * 4; // 32
  static const double xxl = base * 6; // 48
}

/// Corner-radius tokens from DESIGN.md `rounded` block. "Ultra-rounded /
/// pill-shaped" shape language — do not reduce these radii.
abstract final class AppRadius {
  static const double sm = 8; // 0.5rem
  static const double base = 16; // 1rem
  static const double md = 24; // 1.5rem — standard card radius
  static const double lg = 32; // 2rem
  static const double xl = 48; // 3rem
  static const double full = 9999; // pill / full round
  static const double image = 20; // product/photo radius per DESIGN.md
}
