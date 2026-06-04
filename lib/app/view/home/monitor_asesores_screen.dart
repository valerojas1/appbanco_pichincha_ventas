import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
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
                  child: GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(-12.0464, -77.0428),
                      zoom: 11,
                    ),
                    markers: vm.marcadores,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.circle, color: AppTheme.amarillo, size: 10),
                      SizedBox(width: 6),
                      Text(
                        'Última ubicación registrada en cartera del día',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
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
          '(${ (item.progreso * 100).toStringAsFixed(0)}%)',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: item.latitud != null
            ? const Icon(Icons.location_on, color: AppTheme.amarillo, size: 20)
            : const Icon(Icons.location_off, color: Colors.white24, size: 20),
      ),
    );
  }
}
