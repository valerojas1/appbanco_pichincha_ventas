import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/estado_solicitud.dart';
import '../../model/solicitud_resumen_model.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/oficial_scaffold.dart';
import '../../viewmodel/auth_oficial_viewmodel.dart';
import '../../viewmodel/solicitudes_tablero_viewmodel.dart';
import 'solicitud_detalle_screen.dart';

class SolicitudesTableroScreen extends StatefulWidget {
  final bool embedded;

  const SolicitudesTableroScreen({super.key, this.embedded = false});

  @override
  State<SolicitudesTableroScreen> createState() =>
      _SolicitudesTableroScreenState();
}

class _SolicitudesTableroScreenState extends State<SolicitudesTableroScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: TabSolicitud.values.length,
      vsync: this,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        context.read<SolicitudesTableroViewModel>().cambiarTab(
              TabSolicitud.values[_tabController.index],
            );
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _iniciar());
  }

  void _iniciar() {
    final asesor = context.read<AuthOficialViewModel>().oficial?.asesorid;
    if (asesor != null) {
      context.read<SolicitudesTableroViewModel>().iniciar(asesor);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SolicitudesTableroViewModel>();

    return OficialScaffold(
      embedded: widget.embedded,
      title: 'Estado de solicitudes',
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: AppTheme.amarillo,
            labelColor: AppTheme.amarillo,
            unselectedLabelColor: Colors.white54,
            tabs: TabSolicitud.values.map((t) {
              final n = vm.contadores[t] ?? 0;
              return Tab(text: '${t.titulo} ($n)');
            }).toList(),
          ),
          Expanded(
            child: vm.cargando
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.amarillo),
                  )
                : vm.lista.isEmpty
                    ? const Center(
                        child: Text(
                          'Sin solicitudes en esta pestaña',
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: vm.refrescar,
                        color: AppTheme.amarillo,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: vm.lista.length,
                          itemBuilder: (context, i) => _TarjetaSolicitud(
                            solicitud: vm.lista[i],
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SolicitudDetalleScreen(
                                    solicitudId: vm.lista[i].id,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaSolicitud extends StatelessWidget {
  final SolicitudResumenModel solicitud;
  final VoidCallback onTap;

  const _TarjetaSolicitud({
    required this.solicitud,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = solicitud.estado?.color ?? AppTheme.amarillo;

    return Card(
      color: AppTheme.superficie,
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      solicitud.nombreCliente,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: color),
                    ),
                    child: Text(
                      solicitud.estado?.etiqueta ?? '—',
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'S/ ${solicitud.monto.toStringAsFixed(0)}',
                style: const TextStyle(color: AppTheme.amarillo, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                '${solicitud.diasDesdeEnvio} día(s) desde envío',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
              if (solicitud.analistaAsignado != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Analista: ${solicitud.analistaAsignado}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
              if (solicitud.numeroExpediente != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Exp. ${solicitud.numeroExpediente}',
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
