import 'package:flutter/material.dart';
import 'package:lifeflow_app/core/theme/app_colors.dart';
import 'package:lifeflow_app/core/theme/app_palette.dart';

abstract final class AppTheme {
  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    palette: AppPalette.dark,
    background: AppColors.background,
    surface: AppColors.surface,
    primary: AppColors.primary,
    onSurface: AppColors.textPrimary,
    critical: AppColors.critical,
  );

  static ThemeData get light => _build(
    brightness: Brightness.light,
    palette: AppPalette.light,
    background: AppColorsLight.background,
    surface: AppColorsLight.surface,
    primary: AppColorsLight.primary,
    onSurface: AppColorsLight.textPrimary,
    critical: AppColorsLight.critical,
  );

  static ThemeData _build({
    required Brightness brightness,
    required AppPalette palette,
    required Color background,
    required Color surface,
    required Color primary,
    required Color onSurface,
    required Color critical,
  }) {
    final onPrimary = brightness == Brightness.dark
        ? AppColors.background
        : Colors.white;
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: brightness,
          surface: surface,
        ).copyWith(
          primary: primary,
          onPrimary: onPrimary,
          surface: surface,
          onSurface: onSurface,
          error: critical,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      colorScheme: colorScheme,
      extensions: [palette],
      textTheme: TextTheme(
        headlineMedium: TextStyle(color: onSurface, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(color: onSurface),
        bodyMedium: TextStyle(color: palette.textSecondary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
