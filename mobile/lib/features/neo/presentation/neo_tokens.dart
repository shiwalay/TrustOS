import 'package:flutter/material.dart';

/// Neo-Minimal Intelligence design tokens — "Less interface. More
/// intelligence." A deliberately single (light) visual world: one accent,
/// generous whitespace, 8-pt spacing, soft radii, minimal shadow. Scoped to
/// the Neo preview surfaces; does not touch the app's navy/gold brand.
abstract final class Neo {
  // Color
  static const bg = Color(0xFFFAFAFA);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF111827);
  static const text2 = Color(0xFF6B7280);
  static const divider = Color(0xFFE5E7EB);
  static const accent = Color(0xFF2563EB);
  static const accentSoft = Color(0x142563EB); // 8% accent
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);

  // Spacing (8-pt system)
  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s20 = 20.0;
  static const s24 = 24.0;
  static const s32 = 32.0;
  static const s40 = 40.0;
  static const s48 = 48.0;

  // Radii
  static const rSm = 12.0;
  static const rMd = 16.0;
  static const rLg = 20.0;

  // Soft, sparing elevation
  static const shadow = <BoxShadow>[
    BoxShadow(color: Color(0x0A111827), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const family = 'Inter';

  /// Type scale (display 34–40, h1 30, h2 24, h3 20, body 16, small 14,
  /// caption 12). Comfortable line height, sparing weights.
  static const display = TextStyle(
      fontFamily: family, fontSize: 36, height: 1.15,
      fontWeight: FontWeight.w700, color: text, letterSpacing: -0.5);
  static const h1 = TextStyle(
      fontFamily: family, fontSize: 30, height: 1.2,
      fontWeight: FontWeight.w700, color: text, letterSpacing: -0.3);
  static const h2 = TextStyle(
      fontFamily: family, fontSize: 24, height: 1.25,
      fontWeight: FontWeight.w600, color: text);
  static const h3 = TextStyle(
      fontFamily: family, fontSize: 20, height: 1.3,
      fontWeight: FontWeight.w600, color: text);
  static const body = TextStyle(
      fontFamily: family, fontSize: 16, height: 1.5,
      fontWeight: FontWeight.w400, color: text);
  static const bodyStrong = TextStyle(
      fontFamily: family, fontSize: 16, height: 1.5,
      fontWeight: FontWeight.w600, color: text);
  static const small = TextStyle(
      fontFamily: family, fontSize: 14, height: 1.45,
      fontWeight: FontWeight.w400, color: text2);
  static const caption = TextStyle(
      fontFamily: family, fontSize: 12, height: 1.4,
      fontWeight: FontWeight.w500, color: text2, letterSpacing: 0.2);

  /// A light Material theme so system widgets inherit the language.
  static ThemeData theme() {
    final scheme = const ColorScheme.light(
      primary: accent,
      surface: surface,
      onPrimary: Colors.white,
      onSurface: text,
      error: error,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      fontFamily: family,
      splashFactory: InkSparkle.splashFactory,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          elevation: 0,
          textStyle: bodyStrong,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(rMd)),
        ),
      ),
    );
  }
}
