import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Light ("tag stock") and dark ("carbon stock") themes.
///
/// Colors come from Material 3 color roles, so every widget picks the
/// right value in both modes. Type: Barlow Condensed for headings and
/// legends, Barlow for text, JetBrains Mono for asset codes (see [mono]).
class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(_lightScheme);
  static ThemeData get dark => _build(_darkScheme);

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.teal,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: AppColors.tealContainer,
    onPrimaryContainer: Color(0xFF03312F),
    secondary: Color(0xFF2B3E55),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFDDE6EE),
    onSecondaryContainer: Color(0xFF0E1A2B),
    tertiary: Color(0xFFC2410C),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFFE2D2),
    onTertiaryContainer: Color(0xFF5C1A00),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF9DEDC),
    onErrorContainer: Color(0xFF410E0B),
    surface: AppColors.stock,
    onSurface: AppColors.ink,
    onSurfaceVariant: Color(0xFF475869),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF8FAFA),
    surfaceContainer: Color(0xFFEAF0EF),
    surfaceContainerHigh: Color(0xFFE1E9E8),
    surfaceContainerHighest: Color(0xFFD8E1E0),
    outline: Color(0xFF6F8090),
    outlineVariant: Color(0xFFC9D4D9),
    inverseSurface: AppColors.ink,
    onInverseSurface: Color(0xFFEEF3F4),
    inversePrimary: AppColors.tealLift,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.tealLift,
    onPrimary: Color(0xFF00332F),
    primaryContainer: Color(0xFF0B4F4B),
    onPrimaryContainer: Color(0xFFBFF1EB),
    secondary: Color(0xFFB8C9DB),
    onSecondary: Color(0xFF1C2D40),
    secondaryContainer: Color(0xFF2B3E55),
    onSecondaryContainer: Color(0xFFDDE6EE),
    tertiary: Color(0xFFFFB38A),
    onTertiary: Color(0xFF4A1700),
    tertiaryContainer: Color(0xFF7A2E0B),
    onTertiaryContainer: Color(0xFFFFE2D2),
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF601410),
    errorContainer: Color(0xFF8C1D18),
    onErrorContainer: Color(0xFFF9DEDC),
    surface: AppColors.carbon,
    onSurface: Color(0xFFE6EEF0),
    onSurfaceVariant: Color(0xFFA9BAC2),
    surfaceContainerLowest: Color(0xFF070D10),
    surfaceContainerLow: Color(0xFF111B20),
    surfaceContainer: Color(0xFF17242A),
    surfaceContainerHigh: Color(0xFF1E2D34),
    surfaceContainerHighest: Color(0xFF26383F),
    outline: Color(0xFF6E8590),
    outlineVariant: Color(0xFF2E434B),
    inverseSurface: Color(0xFFE6EEF0),
    onInverseSurface: Color(0xFF0E1A2B),
    inversePrimary: AppColors.teal,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );

  /// Monospace style for asset codes and quantities.
  static TextStyle mono(BuildContext context, {double size = 13}) {
    return GoogleFonts.jetBrainsMono(
      fontSize: size,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurface,
      letterSpacing: 0.2,
    );
  }

  static TextTheme _textTheme(ColorScheme s) {
    final base = ThemeData(brightness: s.brightness).textTheme.apply(
      bodyColor: s.onSurface,
      displayColor: s.onSurface,
    );

    // Built from single styles (not GoogleFonts.xxxTextTheme) so the
    // result is always Flutter's own TextTheme type.
    TextStyle? body(TextStyle? t) => t == null ? null : GoogleFonts.barlow(textStyle: t);
    TextStyle? condensed(TextStyle? t, {double ls = 0, double? size}) => t == null
        ? null
        : GoogleFonts.barlowCondensed(
            textStyle: t,
            fontWeight: FontWeight.w600,
            letterSpacing: ls,
            fontSize: size,
          );

    return base.copyWith(
      displayLarge: condensed(base.displayLarge),
      displayMedium: condensed(base.displayMedium),
      displaySmall: condensed(base.displaySmall),
      headlineLarge: condensed(base.headlineLarge),
      headlineMedium: condensed(base.headlineMedium),
      headlineSmall: condensed(base.headlineSmall),
      titleLarge: condensed(base.titleLarge, size: 24),
      titleMedium: body(base.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
      titleSmall: body(base.titleSmall),
      bodyLarge: body(base.bodyLarge),
      bodyMedium: body(base.bodyMedium),
      bodySmall: body(base.bodySmall),
      labelLarge: body(base.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
      labelMedium: condensed(base.labelMedium, ls: 0.9, size: 13),
      labelSmall: condensed(base.labelSmall, ls: 1.1, size: 12),
    );
  }

  static ThemeData _build(ColorScheme scheme) {
    final isLight = scheme.brightness == Brightness.light;
    final text = _textTheme(scheme);
    final radius = BorderRadius.circular(12);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isLight ? scheme.primary : scheme.surfaceContainer,
        foregroundColor: isLight ? scheme.onPrimary : scheme.onSurface,
        titleTextStyle: text.titleLarge?.copyWith(
          color: isLight ? scheme.onPrimary : scheme.onSurface,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        indicatorColor: scheme.primaryContainer,
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(text.labelMedium),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: text.labelLarge?.copyWith(fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: radius),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: text.labelLarge,
        backgroundColor: scheme.surfaceContainerLowest,
        selectedColor: scheme.primaryContainer,
        secondaryLabelStyle: text.labelLarge?.copyWith(color: scheme.onPrimaryContainer),
        checkmarkColor: scheme.onPrimaryContainer,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.surfaceContainerLowest,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.onPrimary
                : scheme.onSurface,
          ),
          side: WidgetStatePropertyAll(BorderSide(color: scheme.outline)),
          textStyle: WidgetStatePropertyAll(text.labelLarge),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLowest,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
    );
  }
}
