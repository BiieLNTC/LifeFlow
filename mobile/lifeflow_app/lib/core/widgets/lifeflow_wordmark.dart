import 'package:flutter/material.dart';
import 'package:lifeflow_app/core/theme/app_palette.dart';

/// Wordmark "LIFEFLOW" (PNG branco, tingido com a cor de marca do tema).
class LifeFlowWordmark extends StatelessWidget {
  const LifeFlowWordmark({super.key, this.height = 16});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo/wordmark.png',
      height: height,
      color: context.colors.primary,
      filterQuality: FilterQuality.high,
      semanticLabel: 'LifeFlow',
    );
  }
}

/// Símbolo LF (PNG branco, tingido com a cor de marca do tema).
class LifeFlowMark extends StatelessWidget {
  const LifeFlowMark({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo/mark.png',
      width: size,
      height: size,
      color: context.colors.primary,
      filterQuality: FilterQuality.high,
      semanticLabel: 'LifeFlow',
    );
  }
}
