import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';
import 'trust_band_colors.dart';

/// Ember theme builder — maps 10-ux-design.md §4.1 tokens onto Material 3.
abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: isDark ? EmberColors.brandPrimaryDark : EmberColors.brandPrimaryLight,
      onPrimary: isDark ? EmberColors.surfaceBaseDark : EmberColors.surfaceRaisedLight,
      primaryContainer: isDark ? EmberColors.brandInkLight : EmberColors.brandInkDark,
      onPrimaryContainer: isDark ? EmberColors.brandInkDark : EmberColors.brandInkLight,
      secondary: isDark ? EmberColors.infoDark : EmberColors.infoLight,
      onSecondary: isDark ? EmberColors.surfaceBaseDark : EmberColors.surfaceRaisedLight,
      tertiary: isDark ? EmberColors.brandGoldDark : EmberColors.brandGoldLight,
      onTertiary: isDark ? EmberColors.surfaceBaseDark : EmberColors.surfaceRaisedLight,
      error: isDark ? EmberColors.criticalDark : EmberColors.criticalLight,
      onError: isDark ? EmberColors.surfaceBaseDark : EmberColors.surfaceRaisedLight,
      surface: isDark ? EmberColors.surfaceBaseDark : EmberColors.surfaceBaseLight,
      onSurface: isDark ? EmberColors.textPrimaryDark : EmberColors.textPrimaryLight,
      surfaceContainerHighest:
          isDark ? EmberColors.surfaceSunkenDark : EmberColors.surfaceSunkenLight,
      surfaceContainer:
          isDark ? EmberColors.surfaceRaisedDark : EmberColors.surfaceRaisedLight,
      onSurfaceVariant:
          isDark ? EmberColors.textSecondaryDark : EmberColors.textSecondaryLight,
      outline: isDark ? EmberColors.textSecondaryDark : EmberColors.textSecondaryLight,
    );

    final textTheme = TextTheme(
      displaySmall: EmberTypography.display,
      headlineMedium: EmberTypography.headline,
      titleMedium: EmberTypography.title,
      bodyLarge: EmberTypography.body,
      bodyMedium: EmberTypography.secondary,
      bodySmall: EmberTypography.caption,
      labelLarge: EmberTypography.secondary.copyWith(fontWeight: FontWeight.w600),
    ).apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        titleTextStyle: EmberTypography.brandDisplay.copyWith(
          fontSize: 22,
          height: 28 / 22,
          color: colorScheme.onSurface,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.tertiary.withValues(alpha: 0.16),
        labelTextStyle: WidgetStatePropertyAll(
          EmberTypography.caption.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainer,
        elevation: isDark ? 0 : 1, // dark swaps shadow for tonal lift (§4.1)
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EmberRadii.card),
          side: isDark
              ? BorderSide(
                  color: colorScheme.tertiary.withValues(alpha: 0.18),
                  width: 0.6,
                )
              : BorderSide.none,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EmberRadii.chip),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: EmberTypography.body.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(EmberRadii.button),
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(EmberRadii.sheetTop),
          ),
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[
        isDark ? const TrustBandColors.dark() : const TrustBandColors.light(),
      ],
    );
  }
}
