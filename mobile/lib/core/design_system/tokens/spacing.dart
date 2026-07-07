/// Ember spacing / radius tokens — 10-ux-design.md §4.1.
/// 4-pt grid; screen gutter 16; card padding 16.
abstract final class EmberSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const double screenGutter = md;
  static const double cardPadding = md;

  /// Minimum touch target (09-mobile-architecture.md §7).
  static const double minTouchTarget = 48;
}

abstract final class EmberRadii {
  static const double chip = 8;
  static const double button = 12;
  static const double card = 16;
  static const double sheetTop = 24;
}
