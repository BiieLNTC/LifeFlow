import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF0D0F12);
  static const surface = Color(0xFF171A1F);
  static const primary = Color(0xFF61E786);
  static const textPrimary = Color(0xFFF4F5F7);
  static const textSecondary = Color(0xFFA6ABB4);
  static const warning = Color(0xFFFFB547);
  static const critical = Color(0xFFFF5D5D);
}

/// Paleta clara: mesma identidade (verde/âmbar/vermelho semânticos), com
/// contraste recalculado para fundo claro — não é o dark theme invertido.
abstract final class AppColorsLight {
  static const background = Color(0xFFF5F6F8);
  static const surface = Color(0xFFFFFFFF);
  static const primary = Color(0xFF1E9E52);
  static const textPrimary = Color(0xFF13161A);
  static const textSecondary = Color(0xFF5B6270);
  static const warning = Color(0xFFB3720A);
  static const critical = Color(0xFFD53A3A);
}
