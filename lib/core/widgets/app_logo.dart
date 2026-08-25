import 'package:flutter/material.dart';

/// The single source of truth for the QuickerX brand mark. Two variants
/// are bundled from the same source artwork:
///
/// - [AppLogoVariant.full] — the full lockup (emblem + "QuickerX" wordmark
///   + "Faster. Smarter. Delivered." tagline), used on Splash where there's
///   room to show the whole thing.
/// - [AppLogoVariant.mark] — just the Q/X emblem (no text), cropped from
///   the same source file, for compact spots like the Login screen header
///   and the small brand mark on Finding Delivery Hub.
///
/// Both assets have a transparent background, so they can sit on any
/// surface color without a visible box behind them.
enum AppLogoVariant { full, mark }

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.variant = AppLogoVariant.mark, this.height = 64});

  final AppLogoVariant variant;

  /// Height of the logo; width follows automatically from the source
  /// image's own aspect ratio (the mark is wide — ~1.9:1 — so don't force
  /// a square box around it).
  final double height;

  @override
  Widget build(BuildContext context) {
    final asset = variant == AppLogoVariant.full ? 'assets/images/logo.png' : 'assets/images/logo_mark.png';
    return Image.asset(asset, height: height, fit: BoxFit.contain);
  }
}
