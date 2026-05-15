import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/cartera_viewmodel.dart';
import '../../model/cliente_cartera_model.dart';
import '../../ui/theme/app_theme.dart';

class CarteraDiariaScreen extends StatelessWidget {
  const CarteraDiariaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<CarteraViewModel>(context);

    return Scaffold(
      backgroundColor: AppTheme.fondoOscuro,
      appBar: AppBar(
        title: const Text(
          'Cartera del Día',
          style: TextStyle(
              color: AppTheme.amarillo, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.amarillo),
            tooltip: 'Cerrar sesión',
            onPressed: () =>
                Navigator.pushReplacementNamed(context, '/login'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Resumen del día
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.superficie,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppTheme.amarillo.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Contador(
                    valor: vm.totalVisitas,
                    label: 'Total',
                    color: Colors.white),
                _Divisor(),
                _Contador(
                    valor: vm.visitados,
                    label: 'Visitados',
                    color: AppTheme.azulVisitado),
                _Divisor(),
                _Contador(
                    valor: vm.pendientes,
                    label: 'Pendientes',
                    color: AppTheme.verdePendiente),
              ],
            ),
          ),

          // Lista de clientes
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: vm.clientes.length,
              itemBuilder: (context, index) {
                final cliente = vm.clientes[index];
                return _TarjetaCliente(
                  cliente: cliente,
                  onMarcarVisitado: cliente.estado == 'pendiente'
                      ? () => vm.marcarVisitado(index)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaCliente extends StatelessWidget {
  final ClienteCarteraModel cliente;
  final VoidCallback? onMarcarVisitado;

  const _TarjetaCliente(
      {required this.cliente, this.onMarcarVisitado});

  Color get _colorTipo {
    switch (cliente.tipoGestion) {
      case 'renovacion':
        return AppTheme.amarillo;
      case 'nuevo':
        return AppTheme.naranjaNuevo;
      case 'cobranza':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final esVisitado = cliente.estado == 'visitado';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: esVisitado
              ? AppTheme.azulVisitado.withOpacity(0.3)
              : AppTheme.amarillo.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          // Avatar inicial
          CircleAvatar(
            backgroundColor: _colorTipo.withOpacity(0.2),
            child: Text(
              cliente.nombre[0],
              style: TextStyle(
                  color: _colorTipo, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cliente.nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    _Badge(
                        texto: cliente.tipoGestion.toUpperCase(),
                        color: _colorTipo),
                    const SizedBox(width: 6),
                    _Badge(
                      texto: cliente.estado.toUpperCase(),
                      color: esVisitado
                          ? AppTheme.azulVisitado
                          : AppTheme.verdePendiente,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  cliente.direccion,
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),

          // Acción
          if (onMarcarVisitado != null)
            IconButton(
              icon: const Icon(Icons.check_circle_outline,
                  color: AppTheme.verdePendiente),
              onPressed: onMarcarVisitado,
              tooltip: 'Marcar visitado',
            )
          else
            const Icon(Icons.check_circle,
                color: AppTheme.azulVisitado, size: 22),
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
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(texto,
          style: TextStyle(
              color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}

class _Contador extends StatelessWidget {
  final int valor;
  final String label;
  final Color color;
  const _Contador(
      {required this.valor, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$valor',
            style: TextStyle(
                color: color,
                fontSize: 26,
                fontWeight: FontWeight.bold)),
        Text(label,
            style:
                const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}

class _Divisor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        height: 36,
        width: 1,
        color: Colors.white12);
  }
}