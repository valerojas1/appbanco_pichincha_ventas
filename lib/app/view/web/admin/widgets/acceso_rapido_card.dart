import 'package:flutter/material.dart';
import '../../../../ui/theme/app_theme.dart';

/// Tarjeta de acceso rápido estilo dashboard web (como referencia de diseño).
class AccesoRapidoCard extends StatelessWidget {
  final IconData icono;
  final Color colorIcono;
  final Color fondoIcono;
  final String titulo;
  final String descripcion;
  final VoidCallback onTap;

  const AccesoRapidoCard({
    super.key,
    required this.icono,
    required this.colorIcono,
    required this.fondoIcono,
    required this.titulo,
    required this.descripcion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.superficie,
      borderRadius: BorderRadius.circular(14),
      elevation: 2,
      shadowColor: Colors.black45,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: fondoIcono,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icono, color: colorIcono, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descripcion,
                      style: const TextStyle(
                        color: AppTheme.grisMedio,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withValues(alpha: 0.35),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
