import 'package:flutter/material.dart';
import 'package:lifeflow_app/core/theme/app_colors.dart';

/// Paleta semântica do app, resolvida a partir do [Theme] atual — permite que
/// o mesmo widget funcione em dark e light sem hardcodar cor. Use via
/// `context.colors` em vez de `AppColors`/`AppColorsLight` diretamente.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.primary,
    required this.textPrimary,
    required this.textSecondary,
    required this.warning,
    required this.critical,
  });

  final Color background, surface, primary, textPrimary, textSecondary;
  final Color warning, critical;

  static const dark = AppPalette(
    background: AppColors.background,
    surface: AppColors.surface,
    primary: AppColors.primary,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    warning: AppColors.warning,
    critical: AppColors.critical,
  );

  static const light = AppPalette(
    background: AppColorsLight.background,
    surface: AppColorsLight.surface,
    primary: AppColorsLight.primary,
    textPrimary: AppColorsLight.textPrimary,
    textSecondary: AppColorsLight.textSecondary,
    warning: AppColorsLight.warning,
    critical: AppColorsLight.critical,
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? primary,
    Color? textPrimary,
    Color? textSecondary,
    Color? warning,
    Color? critical,
  }) => AppPalette(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    primary: primary ?? this.primary,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    warning: warning ?? this.warning,
    critical: critical ?? this.critical,
  );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      critical: Color.lerp(critical, other.critical, t)!,
    );
  }
}

extension AppPaletteX on BuildContext {
  AppPalette get colors => Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;
}
