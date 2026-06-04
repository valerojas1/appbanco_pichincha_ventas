import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/clientes_credito_viewmodel.dart';
import '../../ui/theme/app_theme.dart';
import 'widgets/tarjeta_cliente_financiero.dart';

class ClientesPichinchaTab extends StatelessWidget {
  const ClientesPichinchaTab({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ClientesCreditoViewModel>();

    if (vm.loadingActivos) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.amarillo),
      );
    }

    if (vm.errorActivos != null) {
      return _EstadoVacio(
        mensaje: vm.errorActivos!,
        onReintentar: () => vm.cargarClientesActivos(),
      );
    }

    return RefreshIndicator(
      onRefresh: vm.cargarClientesActivos,
      color: AppTheme.amarillo,
      child: vm.clientesActivos.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(
                  child: Text(
                    'No hay clientes activos registrados',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ],
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                _ResumenCabecera(
                  titulo: 'Cartera Pichincha',
                  subtitulo:
                      '${vm.totalActivos} clientes con relación activa en el banco',
                  color: AppTheme.amarillo,
                ),
                const SizedBox(height: 8),
                ...vm.clientesActivos.map(
                  (c) => TarjetaClienteFinanciero(
                    cliente: c,
                    mostrarDetalleCredito: true,
                  ),
                ),
              ],
            ),
    );
  }
}

class _ResumenCabecera extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final Color color;

  const _ResumenCabecera({
    required this.titulo,
    required this.subtitulo,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitulo,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _EstadoVacio extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;

  const _EstadoVacio({required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(mensaje, style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onReintentar,
            child: const Text('Reintentar',
                style: TextStyle(color: AppTheme.amarillo)),
          ),
        ],
      ),
    );
  }
}
