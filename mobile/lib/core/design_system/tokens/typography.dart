import 'package:flutter/painting.dart';

/// Ember type scale — 10-ux-design.md §4.1.
/// `display 32/38 · headline 24/30 · title 18/24 · body 16/24 ·
///  secondary 14/20 · caption 12/16 · scoreXL 44/48 (tabular, semibold)`.
/// Family: Inter + Noto per script; the skeleton relies on platform fallback.
abstract final class EmberTypography {
  /// One font family across the whole app (directive: no decorative fonts).
  static const family = 'Inter';

  static const display = TextStyle(
    fontFamily: family,
    fontSize: 32,
    height: 38 / 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
  );

  /// Brand display — the hero voice ("Your network is your net worth.").
  /// Now Inter (bold, tight) — a single typographic system, no serif.
  static const brandDisplay = TextStyle(
    fontFamily: family,
    fontSize: 34,
    height: 42 / 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
  );

  /// Wordmark — small, generously letterspaced caps ("T R U S T O S").
  static const wordmark = TextStyle(
    fontFamily: family,
    fontSize: 13,
    height: 16 / 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 4,
  );
  static const headline = TextStyle(
    fontSize: 24,
    height: 30 / 24,
    fontWeight: FontWeight.w600,
  );
  static const title = TextStyle(
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w600,
  );
  static const body = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
  );
  static const secondary = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
  );
  static const caption = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
  );

  /// Money and scores: tabular numerals, semibold — never proportional digits.
  static const scoreXL = TextStyle(
    fontSize: 44,
    height: 48 / 44,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
