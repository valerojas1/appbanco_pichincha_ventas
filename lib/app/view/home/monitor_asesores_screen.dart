import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/maps_config.dart';
import '../../model/asesor_monitor_model.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/oficial_scaffold.dart';
import '../../viewmodel/monitor_asesores_viewmodel.dart';

class MonitorAsesoresScreen extends StatefulWidget {
  final bool embedded;

  const MonitorAsesoresScreen({super.key, this.embedded = false});

  @override
  State<MonitorAsesoresScreen> createState() => _MonitorAsesoresScreenState();
}

class _MonitorAsesoresScreenState extends State<MonitorAsesoresScreen> {
  final MapController _mapController = MapController();
  bool _estabaCargando = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MonitorAsesoresViewModel>().iniciar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MonitorAsesoresViewModel>();

    if (_estabaCargando && !vm.cargando && vm.marcadores.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ajustarCamara(vm);
      });
    }
    _estabaCargando = vm.cargando;

    return OficialScaffold(
      embedded: widget.embedded,
      title: 'Monitor de asesores',
      body: vm.cargando && vm.lista.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.amarillo),
            )
          : Column(
              children: [
                SizedBox(
                  height: 220,
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: vm.centroMapa,
                          initialZoom: vm.marcadores.isEmpty ? 12 : 11,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.all,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: MapsConfig.osmTileUrl,
                            userAgentPackageName: MapsConfig.osmUserAgent,
                          ),
                          MarkerLayer(markers: vm.marcadores),
                          const RichAttributionWidget(
                            attributions: [
                              TextSourceAttribution(
                                'OpenStreetMap contributors',
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (vm.cargando)
                        ColoredBox(
                          color: AppTheme.fondoOscuro.withValues(alpha: 0.6),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.amarillo,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.circle, color: AppTheme.amarillo, size: 10),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Última ubicación registrada en cartera del día · OpenStreetMap',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: vm.lista.isEmpty
                      ? const Center(
                          child: Text(
                            'Sin datos de cartera para hoy',
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: vm.lista.length,
                          itemBuilder: (_, i) =>
                              _FilaAsesor(item: vm.lista[i]),
                        ),
                ),
              ],
            ),
    );
  }

  void _ajustarCamara(MonitorAsesoresViewModel vm) {
    final puntos = vm.puntosParaEncuadre();
    if (puntos.isEmpty) return;

    if (puntos.length == 1) {
      _mapController.move(puntos.first, 13);
      return;
    }

    var minLat = puntos.first.latitude;
    var maxLat = puntos.first.latitude;
    var minLng = puntos.first.longitude;
    var maxLng = puntos.first.longitude;

    for (final p in puntos) {
      minLat = minLat < p.latitude ? minLat : p.latitude;
      maxLat = maxLat > p.latitude ? maxLat : p.latitude;
      minLng = minLng < p.longitude ? minLng : p.longitude;
      maxLng = maxLng > p.longitude ? maxLng : p.longitude;
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(
          LatLng(minLat - 0.01, minLng - 0.01),
          LatLng(maxLat + 0.01, maxLng + 0.01),
        ),
        padding: const EdgeInsets.all(24),
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}

class _FilaAsesor extends StatelessWidget {
  final AsesorMonitorResumen item;

  const _FilaAsesor({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.superficie,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          'Asesor ${item.asesorid}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Visitados ${item.visitados} / ${item.total} '
          '(${(item.progreso * 100).toStringAsFixed(0)}%)',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: item.latitud != null
            ? const Icon(Icons.location_on, color: AppTheme.amarillo, size: 20)
            : const Icon(Icons.location_off, color: Colors.white24, size: 20),
      ),
    );
  }
}
