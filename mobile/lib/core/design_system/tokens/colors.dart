import 'dart:ui';

/// Ember color tokens — premium evolution of 10-ux-design.md §4.1 / §4.2.
/// Brand direction: "world-class premium networking" — deep navy ink +
/// champagne gold on warm ivory (light) / midnight navy (dark). Gold is
/// reserved for brand moments and the trust artifact; it must never read
/// as a status color. Raw tokens only; semantic mapping in the theme.
abstract final class EmberColors {
  // surface.* — warm ivory / midnight navy
  static const surfaceBaseLight = Color(0xFFFAF8F4);
  static const surfaceBaseDark = Color(0xFF0A1220);
  static const surfaceRaisedLight = Color(0xFFFFFFFF);
  static const surfaceRaisedDark = Color(0xFF111B2E);
  static const surfaceSunkenLight = Color(0xFFF1EDE5);
  static const surfaceSunkenDark = Color(0xFF060B14);

  // text.*
  static const textPrimaryLight = Color(0xFF16202E);
  static const textPrimaryDark = Color(0xFFF3F0E9);
  static const textSecondaryLight = Color(0xFF5A6472);
  static const textSecondaryDark = Color(0xFFA3ACBC);

  // brand.* — navy ink; champagne gold carries the brand in dark mode
  static const brandPrimaryLight = Color(0xFF13294B); // deep navy
  static const brandPrimaryDark = Color(0xFFD4B36A); // champagne gold
  static const brandInkLight = Color(0xFF0B1D3A);
  static const brandInkDark = Color(0xFFC9D8F0);

  // brand accent — gold, both modes (hairlines, brand moments)
  static const brandGoldLight = Color(0xFFA98B45);
  static const brandGoldDark = Color(0xFFD9BC7A);

  // Semantic status — the approved Neo palette (success/warning/error).
  // Slightly deepened from the reference hexes for AA text contrast; these
  // are the only non-accent colors, used for status/progress only.
  static const positiveLight = Color(0xFF16A34A); // success (Neo #22C55E)
  static const positiveDark = Color(0xFF22C55E);
  static const cautionLight = Color(0xFFB45309); // warning (Neo #F59E0B)
  static const cautionDark = Color(0xFFF59E0B);
  static const criticalLight = Color(0xFFDC2626); // error (Neo #EF4444)
  static const criticalDark = Color(0xFFEF4444);
  // Info == the single Neo accent (blue); teal is off-palette and removed.
  static const infoLight = Color(0xFF2563EB);
  static const infoDark = Color(0xFF2563EB);

  // Trust bands (§4.2) — colorblind-safe, no red↔green axis.
  static const bandStarterLight = Color(0xFF64748B); // slate
  static const bandStarterDark = Color(0xFF94A3B8);
  static const bandBronzeLight = Color(0xFF9C6644); // copper
  static const bandBronzeDark = Color(0xFFC68B5E);
  static const bandSilverLight = Color(0xFF6E7B8B); // steel
  static const bandSilverDark = Color(0xFF9FB1C1);
  static const bandGoldLight = Color(0xFFB08900); // amber
  static const bandGoldDark = Color(0xFFE3B341);
  static const bandPlatinumLight = Color(0xFF6D5BD0); // violet
  static const bandPlatinumDark = Color(0xFF9D8DF1);
}
