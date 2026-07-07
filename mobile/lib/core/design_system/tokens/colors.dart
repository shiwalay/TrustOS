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

  // semantic
  static const positiveLight = Color(0xFF1B7F4D); // confirmed money, success
  static const positiveDark = Color(0xFF4CC38A);
  static const cautionLight = Color(0xFF9A6700); // pending, offline, expiring
  static const cautionDark = Color(0xFFE2B93B);
  static const criticalLight = Color(0xFFB3261E); // errors — never score drops
  static const criticalDark = Color(0xFFF2705D);
  static const infoLight = Color(0xFF0B6E7F);
  static const infoDark = Color(0xFF57C2D4);

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
