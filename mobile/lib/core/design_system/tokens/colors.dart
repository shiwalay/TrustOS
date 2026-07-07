import 'dart:ui';

/// Ember color tokens — verbatim from 10-ux-design.md §4.1 / §4.2.
/// Raw tokens only; semantic mapping happens in the theme builder.
abstract final class EmberColors {
  // surface.*
  static const surfaceBaseLight = Color(0xFFFAF8F5);
  static const surfaceBaseDark = Color(0xFF121417);
  static const surfaceRaisedLight = Color(0xFFFFFFFF);
  static const surfaceRaisedDark = Color(0xFF1C1F24);
  static const surfaceSunkenLight = Color(0xFFF1EDE7);
  static const surfaceSunkenDark = Color(0xFF0C0E11);

  // text.*
  static const textPrimaryLight = Color(0xFF1A1D21);
  static const textPrimaryDark = Color(0xFFF2F0EC);
  static const textSecondaryLight = Color(0xFF5C6470);
  static const textSecondaryDark = Color(0xFFA8AEB8);

  // brand.*
  static const brandPrimaryLight = Color(0xFF1E5AE8);
  static const brandPrimaryDark = Color(0xFF6C9BFF);
  static const brandInkLight = Color(0xFF0E2A6B);
  static const brandInkDark = Color(0xFFB9CFFF);

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
