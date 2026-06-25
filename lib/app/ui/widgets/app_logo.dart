import 'package:flutter/material.dart';
import '../../core/app_assets.dart';
import '../theme/app_theme.dart';

/// Logo de la app (misma imagen que el icono del launcher).
class AppLogo extends StatelessWidget {
  final double size;
  final double borderRadius;

  const AppLogo({
    super.key,
    this.size = 90,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        AppAssets.appIcon,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _LogoPlaceholder(size: size),
      ),
    );
  }
}

class _LogoPlaceholder extends StatelessWidget {
  final double size;

  const _LogoPlaceholder({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.amarillo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: size * 0.2,
            top: size * 0.2,
            child: Container(
              width: size * 0.18,
              height: size * 0.49,
              color: AppTheme.fondoOscuro,
            ),
          ),
          Positioned(
            left: size * 0.2,
            bottom: size * 0.2,
            child: Container(
              width: size * 0.4,
              height: size * 0.18,
              color: AppTheme.fondoOscuro,
            ),
          ),
        ],
      ),
    );
  }
}
