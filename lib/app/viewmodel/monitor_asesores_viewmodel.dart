import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../model/asesor_monitor_model.dart';
import '../services/monitor_asesores_service.dart';

class MonitorAsesoresViewModel extends ChangeNotifier {
  final MonitorAsesoresService _service = MonitorAsesoresService();

  List<AsesorMonitorResumen> _lista = [];
  Set<Marker> _marcadores = {};
  bool _cargando = false;

  List<AsesorMonitorResumen> get lista => _lista;
  Set<Marker> get marcadores => _marcadores;
  bool get cargando => _cargando;

  Future<void> iniciar() async {
    _service.suscribirCambios(() => refrescar());
    await refrescar();
  }

  Future<void> refrescar() async {
    _cargando = true;
    notifyListeners();

    _lista = await _service.cargarResumenHoy();
    _marcadores = {};
    for (final a in _lista) {
      if (a.latitud != null && a.longitud != null) {
        _marcadores.add(
          Marker(
            markerId: MarkerId(a.asesorid),
            position: LatLng(a.latitud!, a.longitud!),
            infoWindow: InfoWindow(
              title: a.nombreAsesor,
              snippet: '${a.visitados}/${a.total} visitados',
            ),
          ),
        );
      }
    }

    _cargando = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _service.cancelarSuscripcion();
    super.dispose();
  }
}
