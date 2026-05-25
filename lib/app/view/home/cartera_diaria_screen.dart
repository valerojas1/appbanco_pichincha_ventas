import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/cartera_viewmodel.dart';
import '../../viewmodel/auth_oficial_viewmodel.dart';
import '../../ui/theme/app_theme.dart';

class CarteraDiariaScreen extends StatefulWidget {
  const CarteraDiariaScreen({super.key});

  @override
  State<CarteraDiariaScreen> createState() => _CarteraDiariaScreenState();
}

class _CarteraDiariaScreenState extends State<CarteraDiariaScreen> {
  @override
  void initState() {
    super.initState();
    final oficial = context.read<AuthOficialViewModel>().oficial;
    if (oficial != null) {
      context.read<CarteraViewModel>().cargarRuta(oficial.userid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CarteraViewModel>();

    return Scaffold(
      backgroundColor: AppTheme.fondoOscuro,
      appBar: AppBar(
        title: const Text(
          'Cartera del Día',
          style:
              TextStyle(color: AppTheme.amarillo, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.amarillo),
            tooltip: 'Cerrar sesión',
            onPressed: () {
              context.read<AuthOficialViewModel>().logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.amarillo))
          : Column(
              children: [
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
                Expanded(
                  child: vm.rutas.isEmpty
                      ? const Center(child: Text('Sin visitas para hoy',
                          style: TextStyle(color: Colors.white54)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: vm.rutas.length,
                          itemBuilder: (context, index) {
                            final ruta = vm.rutas[index];
                            return _TarjetaCliente(
                              nombre: ruta.nombrecliente,
                              dni: '',
                              tipoGestion: ruta.tipogestion,
                              estado: ruta.estadovisita,
                              direccion: ruta.direccion,
                              onMarcarVisitado: ruta.estadovisita == 'pendiente'
                                  ? () => vm.marcarVisitado(ruta.rutaid)
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
  final String nombre;
  final String dni;
  final String tipoGestion;
  final String estado;
  final String direccion;
  final VoidCallback? onMarcarVisitado;

  const _TarjetaCliente({
    required this.nombre,
    required this.dni,
    required this.tipoGestion,
    required this.estado,
    required this.direccion,
    this.onMarcarVisitado,
  });

  Color get _colorTipo {
    switch (tipoGestion) {
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
    final esVisitado = estado == 'visitado';

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
          CircleAvatar(
            backgroundColor: _colorTipo.withOpacity(0.2),
            child: Text(
              nombre.isNotEmpty ? nombre[0] : '?',
              style: TextStyle(
                  color: _colorTipo, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
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
                        texto: tipoGestion.toUpperCase(),
                        color: _colorTipo),
                    const SizedBox(width: 6),
                    _Badge(
                      texto: estado.toUpperCase(),
                      color: esVisitado
                          ? AppTheme.azulVisitado
                          : AppTheme.verdePendiente,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  direccion,
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
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
    return Container(height: 36, width: 1, color: Colors.white12);
  }
}
