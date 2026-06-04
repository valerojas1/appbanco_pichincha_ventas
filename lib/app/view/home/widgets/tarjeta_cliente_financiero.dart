import 'package:flutter/material.dart';
import '../../../model/cliente_financiero_model.dart';
import '../../../ui/theme/app_theme.dart';

class TarjetaClienteFinanciero extends StatelessWidget {
  final ClienteFinancieroModel cliente;
  final bool mostrarDetalleCredito;

  const TarjetaClienteFinanciero({
    super.key,
    required this.cliente,
    this.mostrarDetalleCredito = false,
  });

  Color get _colorSegmento {
    switch (cliente.segmento) {
      case 'A':
        return AppTheme.verdePendiente;
      case 'B':
        return AppTheme.azulVisitado;
      case 'C':
        return AppTheme.amarillo;
      case 'D':
        return AppTheme.naranjaNuevo;
      default:
        return Colors.white38;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cliente.esProspecto
              ? AppTheme.naranjaNuevo.withValues(alpha: 0.35)
              : AppTheme.amarillo.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: _colorSegmento.withValues(alpha: 0.2),
                child: Text(
                  cliente.nombres.isNotEmpty ? cliente.nombres[0] : '?',
                  style: TextStyle(
                    color: _colorSegmento,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cliente.nombreCompleto,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'DNI ${cliente.dni}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (cliente.esProspecto)
                _Badge(texto: 'PROSPECTO', color: AppTheme.naranjaNuevo)
              else if (cliente.segmento != null)
                _Badge(texto: 'SEG. ${cliente.segmento}', color: _colorSegmento),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _Badge(
                texto: cliente.tiponegocio.toUpperCase(),
                color: AppTheme.amarillo,
              ),
              _Badge(
                texto: cliente.zonanegocio.toUpperCase(),
                color: AppTheme.azulVisitado,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _FilaFinanciera(
            icono: Icons.payments_outlined,
            etiqueta: 'Ingreso est.',
            valor: 'S/ ${cliente.ingresomensualest.toStringAsFixed(0)}',
          ),
          _FilaFinanciera(
            icono: Icons.receipt_long_outlined,
            etiqueta: 'Gasto est.',
            valor: 'S/ ${cliente.gastomensualest.toStringAsFixed(0)}',
          ),
          _FilaFinanciera(
            icono: Icons.trending_up,
            etiqueta: 'Flujo neto',
            valor: 'S/ ${cliente.flujonetoestimado.toStringAsFixed(0)}',
            destacado: true,
          ),
          _FilaFinanciera(
            icono: Icons.credit_card_outlined,
            etiqueta: 'Deuda actual',
            valor: 'S/ ${cliente.deudaactual.toStringAsFixed(0)}',
          ),
          if (mostrarDetalleCredito) ...[
            const Divider(color: Colors.white12, height: 20),
            if (cliente.tieneScoring) ...[
              _FilaFinanciera(
                icono: Icons.analytics_outlined,
                etiqueta: 'Score transaccional',
                valor: cliente.scoretransaccional!.toStringAsFixed(0),
                destacado: true,
              ),
              if (cliente.capacidadpago != null)
                _FilaFinanciera(
                  icono: Icons.account_balance_wallet_outlined,
                  etiqueta: 'Capacidad de pago',
                  valor: 'S/ ${cliente.capacidadpago!.toStringAsFixed(0)}',
                ),
              if (cliente.ratiodeudaingreso != null)
                _FilaFinanciera(
                  icono: Icons.pie_chart_outline,
                  etiqueta: 'Ratio deuda/ingreso',
                  valor: cliente.ratiodeudaingreso!.toStringAsFixed(2),
                ),
              if (cliente.montomaxsugerido != null &&
                  cliente.montomaxsugerido! > 0)
                _FilaFinanciera(
                  icono: Icons.attach_money,
                  etiqueta: 'Monto máx. sugerido',
                  valor: 'S/ ${cliente.montomaxsugerido!.toStringAsFixed(0)}',
                  destacado: true,
                ),
              if (cliente.recomendacion != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _recomendacionLegible(cliente.recomendacion!),
                    style: TextStyle(
                      color: _colorSegmento.withValues(alpha: 0.9),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ] else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.naranjaNuevo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.naranjaNuevo.withValues(alpha: 0.3),
                  ),
                ),
                child: const Text(
                  'Sin scoring transaccional — evaluar en campo',
                  style: TextStyle(color: AppTheme.naranjaNuevo, fontSize: 11),
                ),
              ),
            if (cliente.telefono != null && cliente.telefono!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.phone_outlined,
                        color: Colors.white38, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      cliente.telefono!,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _recomendacionLegible(String codigo) {
    switch (codigo) {
      case 'pre_aprobado':
        return 'Recomendación: pre-aprobado';
      case 'evaluar_presencial':
        return 'Recomendación: evaluar en visita';
      case 'rechazar':
        return 'Recomendación: no viable';
      default:
        return 'Recomendación: ${codigo.replaceAll('_', ' ')}';
    }
  }
}

class _FilaFinanciera extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;
  final bool destacado;

  const _FilaFinanciera({
    required this.icono,
    required this.etiqueta,
    required this.valor,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icono, size: 14, color: Colors.white38),
          const SizedBox(width: 8),
          Text(etiqueta,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const Spacer(),
          Text(
            valor,
            style: TextStyle(
              color: destacado ? AppTheme.amarillo : Colors.white,
              fontSize: 12,
              fontWeight: destacado ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String texto;
  final Color color;

  const _Badge({required this.texto, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
