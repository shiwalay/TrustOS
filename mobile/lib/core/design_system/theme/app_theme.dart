import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import '../tokens/typography.dart';
import 'trust_band_colors.dart';

/// Neo-Minimal Intelligence — the single, app-wide visual language
/// (directive: one style, zero exceptions). Light-committed: light() and
/// dark() both return the same Neo theme so every screen is identical
/// regardless of the OS setting. "Less interface. More intelligence."
abstract final class AppTheme {
  // The approved palette — the only colors permitted.
  static const _bg = Color(0xFFFAFAFA);
  static const _surface = Color(0xFFFFFFFF);
  static const _text = Color(0xFF111827);
  static const _text2 = Color(0xFF6B7280);
  static const _divider = Color(0xFFE5E7EB);
  static const _accent = Color(0xFF2563EB);
  static const _sunken = Color(0xFFF3F4F6);
  static const _error = Color(0xFFEF4444);

  static ThemeData light() => _build();
  static ThemeData dark() => _build();

  static ThemeData _build() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: _accent,
      onPrimary: Colors.white,
      primaryContainer: Color(0x142563EB),
      onPrimaryContainer: _accent,
      secondary: _accent,
      onSecondary: Colors.white,
      // One accent only — the former gold `tertiary` now resolves to blue,
      // unifying every screen that reads colorScheme.tertiary.
      tertiary: _accent,
      onTertiary: Colors.white,
      error: _error,
      onError: Colors.white,
      surface: _surface,
      onSurface: _text,
      surfaceContainerHighest: _sunken,
      surfaceContainer: _surface,
      onSurfaceVariant: _text2,
      outline: _divider,
    );

    final textTheme = TextTheme(
      displaySmall: EmberTypography.display,
      headlineMedium: EmberTypography.headline,
      titleMedium: EmberTypography.title,
      bodyLarge: EmberTypography.body,
      bodyMedium: EmberTypography.secondary,
      bodySmall: EmberTypography.caption,
      labelLarge:
          EmberTypography.secondary.copyWith(fontWeight: FontWeight.w600),
    ).apply(bodyColor: _text, displayColor: _text);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      // One font family, everywhere.
      fontFamily: 'Inter',
      scaffoldBackgroundColor: _bg,
      dividerColor: _divider,
      dividerTheme: const DividerThemeData(color: _divider, thickness: 1),
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        centerTitle: false, // Linear/Notion-style left alignment
        backgroundColor: _bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          height: 1.3,
          fontWeight: FontWeight.w600,
          color: _text,
        ),
        iconTheme: IconThemeData(color: _text),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        indicatorColor: const Color(0x142563EB),
        labelTextStyle: WidgetStatePropertyAll(
          EmberTypography.caption.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _text,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected) ? _accent : _text2,
            )),
      ),
      // One card system: white, radius 20, one soft shadow, no border.
      cardTheme: CardThemeData(
        color: _surface,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        margin: EdgeInsets.zero,
        shadowColor: const Color(0x14111827),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _sunken,
        side: BorderSide.none,
        labelStyle: EmberTypography.caption.copyWith(color: _text),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EmberRadii.chip),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          elevation: 0,
          textStyle: EmberTypography.body.copyWith(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _accent,
          // Height for the 48pt touch target; width hugs content so inline
          // outlined buttons don't starve their row neighbours.
          // (Size.fromHeight sets infinite width — deliberately avoided.)
          minimumSize: const Size(0, 48),
          side: const BorderSide(color: _divider),
          textStyle: EmberTypography.body.copyWith(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _accent,
          textStyle: EmberTypography.body.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surface,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _accent, width: 2),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _accent,
        linearTrackColor: _divider,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? Colors.white : _text2),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? _accent : _divider),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _text,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      // Trust bands are status/progress (an allowed color use), kept as the
      // single restrained band palette.
      extensions: const <ThemeExtension<dynamic>>[TrustBandColors.light()],
    );
  }
}
