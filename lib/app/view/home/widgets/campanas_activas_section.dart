import 'package:flutter/material.dart';
import '../../../core/campana_tipo_style.dart';
import '../../../model/campana_activa_model.dart';
import '../../../ui/theme/app_theme.dart';

class CampanasActivasSection extends StatelessWidget {
  final List<CampanaActivaModel> campanas;
  final void Function(CampanaActivaModel) onGestionar;

  const CampanasActivasSection({
    super.key,
    required this.campanas,
    required this.onGestionar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Campañas activas',
          style: TextStyle(
            color: AppTheme.amarillo,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Ordenadas por vencimiento más próximo',
          style: TextStyle(color: Colors.white38, fontSize: 11),
        ),
        const SizedBox(height: 12),
        if (campanas.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.superficie,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'No hay campañas vigentes',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          )
        else
          ...campanas.map((c) => _TarjetaCampana(campana: c, onGestionar: onGestionar)),
      ],
    );
  }
}

class _TarjetaCampana extends StatelessWidget {
  final CampanaActivaModel campana;
  final void Function(CampanaActivaModel) onGestionar;

  const _TarjetaCampana({required this.campana, required this.onGestionar});

  @override
  Widget build(BuildContext context) {
    final color = CampanaTipoStyle.color(campana.tipocampana);
    final dias = campana.diasRestantes;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: color.withValues(alpha: 0.5)),
                ),
                child: Text(
                  CampanaTipoStyle.etiqueta(campana.tipocampana),
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.timer_outlined, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                dias == 0 ? 'Vence hoy' : '$dias días',
                style: TextStyle(
                  color: dias <= 3 ? Colors.redAccent : color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            campana.nombrecliente,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Oferta S/ ${campana.montooferta.toStringAsFixed(0)}',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => onGestionar(campana),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.amarillo,
                side: const BorderSide(color: AppTheme.amarillo),
              ),
              child: const Text('GESTIONAR AHORA'),
            ),
          ),
        ],
      ),
    );
  }
}
