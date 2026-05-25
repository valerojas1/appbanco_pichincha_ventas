import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/ruta_viewmodel.dart';
import '../../viewmodel/auth_oficial_viewmodel.dart';
import '../../ui/theme/app_theme.dart';

class RutaView extends StatefulWidget {
  const RutaView({super.key});

  @override
  State<RutaView> createState() => _RutaViewState();
}

class _RutaViewState extends State<RutaView> {
  @override
  void initState() {
    super.initState();
    final oficial = context.read<AuthOficialViewModel>().oficial;
    if (oficial != null) {
      context.read<RutaViewModel>().cargarRuta(oficial.userid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RutaViewModel>();

    return Scaffold(
      backgroundColor: AppTheme.fondoOscuro,
      appBar: AppBar(
        title: const Text('Ruta del Día',
            style: TextStyle(color: AppTheme.amarillo, fontWeight: FontWeight.bold)),
      ),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.amarillo))
          : vm.rutas.isEmpty
              ? const Center(child: Text('Sin visitas para hoy',
                  style: TextStyle(color: Colors.white54)))
              : RefreshIndicator(
                  onRefresh: () async {
                    final oficial = context.read<AuthOficialViewModel>().oficial;
                    if (oficial != null) {
                      await vm.cargarRuta(oficial.userid);
                    }
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: vm.rutas.length,
                    itemBuilder: (context, index) {
                      final ruta = vm.rutas[index];
                      final esVisitado = ruta.estadovisita == 'visitado';
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
                              backgroundColor: esVisitado
                                  ? AppTheme.azulVisitado.withOpacity(0.2)
                                  : AppTheme.verdePendiente.withOpacity(0.2),
                              child: Text(
                                ruta.nombrecliente.isNotEmpty
                                    ? ruta.nombrecliente[0]
                                    : '?',
                                style: TextStyle(
                                  color: esVisitado
                                      ? AppTheme.azulVisitado
                                      : AppTheme.verdePendiente,
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
                                    ruta.nombrecliente,
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
                                        texto: ruta.tipogestion.toUpperCase(),
                                        color: AppTheme.naranjaNuevo,
                                      ),
                                      const SizedBox(width: 6),
                                      _Badge(
                                        texto: ruta.estadovisita.toUpperCase(),
                                        color: esVisitado
                                            ? AppTheme.azulVisitado
                                            : AppTheme.verdePendiente,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    ruta.direccion,
                                    style: const TextStyle(
                                        color: Colors.white38, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            if (!esVisitado)
                              IconButton(
                                icon: const Icon(Icons.check_circle_outline,
                                    color: AppTheme.verdePendiente),
                                onPressed: () => vm.actualizarEstado(
                                    ruta.rutaid, 'visitado'),
                                tooltip: 'Marcar visitado',
                              )
                            else
                              const Icon(Icons.check_circle,
                                  color: AppTheme.azulVisitado, size: 22),
                          ],
                        ),
                      );
                    },
                  ),
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
