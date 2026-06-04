import 'package:flutter/material.dart';
import '../../../core/cartera_nivel_prioridad.dart';
import '../../../core/cartera_tipo_gestion_style.dart';
import '../../../model/cartera_diaria_model.dart';
import '../../../ui/theme/app_theme.dart';

class FichaRapidaSheet extends StatelessWidget {
  final CarteraDiariaModel cliente;
  final VoidCallback onVerFichaCompleta;
  final VoidCallback onNavegar;
  final VoidCallback onCerrar;

  const FichaRapidaSheet({
    super.key,
    required this.cliente,
    required this.onVerFichaCompleta,
    required this.onNavegar,
    required this.onCerrar,
  });

  @override
  Widget build(BuildContext context) {
    final nivel = cliente.nivelPrioridad;
    final colorPrioridad = CarteraNivelPrioridad.colorMarcador(nivel);
    final colorGestion = CarteraTipoGestionStyle.color(cliente.tipogestion);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: AppTheme.navyOscuro,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: cliente.esVisitado ? Colors.grey : colorPrioridad,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cliente.nombrecliente,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                onPressed: onCerrar,
                icon: const Icon(Icons.close, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Prioridad ${CarteraNivelPrioridad.etiqueta(nivel)} · ${cliente.documentoCensurado}',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Chip(
                texto: CarteraTipoGestionStyle.etiquetaCorta(cliente.tipogestion),
                color: colorGestion,
              ),
              const SizedBox(width: 8),
              Text(
                'S/ ${cliente.monto.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          if (cliente.direccion != null && cliente.direccion!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              cliente.direccion!,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: cliente.tieneCoordenadas ? onNavegar : null,
                  icon: const Icon(Icons.navigation, size: 18),
                  label: const Text('Navegar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.amarillo,
                    side: const BorderSide(color: AppTheme.amarillo),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onVerFichaCompleta,
                  child: const Text('Ver ficha completa'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String texto;
  final Color color;

  const _Chip({required this.texto, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
