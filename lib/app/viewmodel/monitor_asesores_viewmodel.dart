import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/maps_config.dart';
import '../model/asesor_monitor_model.dart';
import '../services/monitor_asesores_service.dart';
import '../ui/theme/app_theme.dart';

class MonitorAsesoresViewModel extends ChangeNotifier {
  final MonitorAsesoresService _service = MonitorAsesoresService();

  List<AsesorMonitorResumen> _lista = [];
  List<Marker> _marcadores = [];
  bool _cargando = false;

  List<AsesorMonitorResumen> get lista => _lista;
  List<Marker> get marcadores => _marcadores;
  bool get cargando => _cargando;

  LatLng get centroMapa {
    if (_marcadores.isNotEmpty) {
      return _marcadores.first.point;
    }
    final c = MapsConfig.centroHuancayo;
    return LatLng(c.latitud, c.longitud);
  }

  Future<void> iniciar() async {
    _service.suscribirCambios(() => refrescar());
    await refrescar();
  }

  Future<void> refrescar() async {
    _cargando = true;
    notifyListeners();

    _lista = await _service.cargarResumenHoy();
    _marcadores = _lista
        .where((a) => a.latitud != null && a.longitud != null)
        .map(
          (a) => Marker(
            point: LatLng(a.latitud!, a.longitud!),
            width: 44,
            height: 52,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on,
                  color: AppTheme.amarillo,
                  size: 28,
                ),
                Text(
                  a.nombreAsesor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(color: Colors.black, blurRadius: 2),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();

    _cargando = false;
    notifyListeners();
  }

  List<LatLng> puntosParaEncuadre() =>
      _marcadores.map((m) => m.point).toList();

  @override
  void dispose() {
    _service.cancelarSuscripcion();
    super.dispose();
  }
}
