import 'package:flutter/material.dart';

import '../tokens/colors.dart';

/// Trust bands per _shared-context.md §4 and 10-ux-design.md §4.2.
///
/// UX rule: a band is ALWAYS encoded three ways — color + label + ring-segment
/// count. Never color alone (colorblind-safe; no red↔green axis).
enum TrustBand {
  starter(0, 249, 1),
  bronze(250, 449, 2),
  silver(450, 649, 3),
  gold(650, 849, 4),
  platinum(850, 1000, 5);

  const TrustBand(this.min, this.max, this.ringSegments);

  final int min;
  final int max;

  /// Filled segments out of 5 on the TrustBandRing — the non-color encoding.
  final int ringSegments;

  static TrustBand fromScore(int score) {
    final clamped = score.clamp(0, 1000);
    return TrustBand.values.lastWhere((b) => clamped >= b.min);
  }

  String get label => switch (this) {
        TrustBand.starter => 'Starter',
        TrustBand.bronze => 'Bronze',
        TrustBand.silver => 'Silver',
        TrustBand.gold => 'Gold',
        TrustBand.platinum => 'Platinum',
      };
}

/// ThemeExtension carrying the band → color mapping for the active brightness,
/// so widgets resolve band colors via `Theme.of(context)` and never hardcode.
@immutable
class TrustBandColors extends ThemeExtension<TrustBandColors> {
  const TrustBandColors({
    required this.starter,
    required this.bronze,
    required this.silver,
    required this.gold,
    required this.platinum,
  });

  const TrustBandColors.light()
      : this(
          starter: EmberColors.bandStarterLight,
          bronze: EmberColors.bandBronzeLight,
          silver: EmberColors.bandSilverLight,
          gold: EmberColors.bandGoldLight,
          platinum: EmberColors.bandPlatinumLight,
        );

  const TrustBandColors.dark()
      : this(
          starter: EmberColors.bandStarterDark,
          bronze: EmberColors.bandBronzeDark,
          silver: EmberColors.bandSilverDark,
          gold: EmberColors.bandGoldDark,
          platinum: EmberColors.bandPlatinumDark,
        );

  final Color starter;
  final Color bronze;
  final Color silver;
  final Color gold;
  final Color platinum;

  Color of(TrustBand band) => switch (band) {
        TrustBand.starter => starter,
        TrustBand.bronze => bronze,
        TrustBand.silver => silver,
        TrustBand.gold => gold,
        TrustBand.platinum => platinum,
      };

  @override
  TrustBandColors copyWith({
    Color? starter,
    Color? bronze,
    Color? silver,
    Color? gold,
    Color? platinum,
  }) =>
      TrustBandColors(
        starter: starter ?? this.starter,
        bronze: bronze ?? this.bronze,
        silver: silver ?? this.silver,
        gold: gold ?? this.gold,
        platinum: platinum ?? this.platinum,
      );

  @override
  TrustBandColors lerp(TrustBandColors? other, double t) {
    if (other == null) return this;
    return TrustBandColors(
      starter: Color.lerp(starter, other.starter, t)!,
      bronze: Color.lerp(bronze, other.bronze, t)!,
      silver: Color.lerp(silver, other.silver, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      platinum: Color.lerp(platinum, other.platinum, t)!,
    );
  }
}
