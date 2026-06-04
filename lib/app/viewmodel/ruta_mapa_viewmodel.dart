import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../core/cartera_nivel_prioridad.dart';
import '../core/geocerca_util.dart';
import '../core/maps_config.dart';
import '../core/ruta_optimizador.dart';
import '../model/cartera_diaria_model.dart';
import '../model/geocerca_zona_model.dart';
import '../model/perfil_oficial.dart';
import '../services/cartera_diaria_service.dart';
import '../services/geocerca_service.dart';
import '../services/navegacion_externa_service.dart';

class RutaMapaViewModel extends ChangeNotifier {
  final CarteraDiariaService _carteraService = CarteraDiariaService();
  final GeocercaService _geocercaService = GeocercaService();
  final NavegacionExternaService _navegacion = NavegacionExternaService();

  List<CarteraDiariaModel> _clientes = [];
  List<GeocercaZonaModel> _geocercas = [];
  LatLng? _posicionActual;
  Set<Marker> _markers = {};
  Set<Polygon> _polygons = {};
  Set<Polyline> _polylines = {};
  bool _loading = false;
  bool _optimizando = false;
  bool _mostrarGeocercas = false;
  String? _asesorid;
  PerfilOficial _perfil = PerfilOficial.operador;
  CarteraDiariaModel? _clienteSeleccionado;
  List<String> _ordenOptimizado = [];

  List<CarteraDiariaModel> get clientes => _clientes;
  List<GeocercaZonaModel> get geocercas => _geocercas;
  LatLng? get posicionActual => _posicionActual;
  Set<Marker> get markers => _markers;
  Set<Polygon> get polygons => _polygons;
  Set<Polyline> get polylines => _polylines;
  bool get loading => _loading;
  bool get optimizando => _optimizando;
  bool get mostrarGeocercas => _mostrarGeocercas;
  CarteraDiariaModel? get clienteSeleccionado => _clienteSeleccionado;
  List<String> get ordenOptimizado => _ordenOptimizado;

  int get conCoordenadas =>
      _clientes.where((c) => c.tieneCoordenadas).length;

  LatLng get centroMapa {
    if (_posicionActual != null) {
      return _posicionActual!;
    }
    final c = MapsConfig.centroHuancayo;
    return LatLng(c.latitud, c.longitud);
  }

  Future<void> cargar({
    required String asesorid,
    required PerfilOficial perfil,
  }) async {
    _asesorid = asesorid;
    _perfil = perfil;
    _mostrarGeocercas = perfil == PerfilOficial.administrador ||
        perfil == PerfilOficial.supervisor;
    _loading = true;
    notifyListeners();

    await _obtenerPosicionActual();
    _clientes = await _carteraService.getCarteraHoy(asesorid);
    _geocercas = await _geocercaService.listarActivas();
    _ordenOptimizado = [];
    _polylines = {};

    _construirMapa();
    _loading = false;
    notifyListeners();
  }

  Future<void> _obtenerPosicionActual() async {
    try {
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      _posicionActual = LatLng(pos.latitude, pos.longitude);
    } catch (_) {}
  }

  void _construirMapa() {
    _markers = _buildMarkers();
    _polygons = _mostrarGeocercas ? _buildPolygons() : {};
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    if (_posicionActual != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('yo'),
          position: _posicionActual!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: 'Tu ubicación'),
        ),
      );
    }

    for (final c in _clientes) {
      if (!c.tieneCoordenadas) continue;
      final nivel = c.nivelPrioridad;
      markers.add(
        Marker(
          markerId: MarkerId(c.id),
          position: LatLng(c.latitud!, c.longitud!),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            CarteraNivelPrioridad.hueMarcador(
              nivel,
              visitado: c.esVisitado,
            ),
          ),
          onTap: () {
            _clienteSeleccionado = c;
            notifyListeners();
          },
        ),
      );
    }

    return markers;
  }

  Set<Polygon> _buildPolygons() {
    return _geocercas.map((z) {
      return Polygon(
        polygonId: PolygonId(z.id),
        points: z.puntos,
        fillColor: z.color.withValues(alpha: 0.18),
        strokeColor: z.color.withValues(alpha: 0.7),
        strokeWidth: 2,
      );
    }).toSet();
  }

  void limpiarSeleccion() {
    _clienteSeleccionado = null;
    notifyListeners();
  }

  Future<void> optimizarRuta() async {
    if (_posicionActual == null) {
      await _obtenerPosicionActual();
    }
    if (_posicionActual == null) return;

    _optimizando = true;
    notifyListeners();

    final coords = <String, LatLng>{};
    for (final c in _clientes) {
      if (c.tieneCoordenadas && !c.esVisitado) {
        coords[c.id] = LatLng(c.latitud!, c.longitud!);
      }
    }

    _ordenOptimizado = RutaOptimizador.ordenarVecinoMasCercano(
      origen: _posicionActual!,
      clientesPorId: coords,
    );

    final puntos = RutaOptimizador.puntosPolilinea(
      origen: _posicionActual!,
      ordenIds: _ordenOptimizado,
      clientesPorId: coords,
    );

    _polylines = {
      Polyline(
        polylineId: const PolylineId('ruta_opt'),
        points: puntos,
        color: const Color(0xFFFFD100),
        width: 4,
        geodesic: true,
      ),
    };

    _optimizando = false;
    notifyListeners();
  }

  Future<bool> navegarA(CarteraDiariaModel cliente) async {
    if (!cliente.tieneCoordenadas) return false;
    return _navegacion.abrirNavegacion(
      latitud: cliente.latitud!,
      longitud: cliente.longitud!,
      etiqueta: cliente.nombrecliente,
    );
  }

  /// Aviso si la visita queda fuera de geocercas (no bloquea).
  String? mensajeGeocercaVisita(double lat, double lng) {
    if (_geocercas.isEmpty) return null;
    final punto = LatLng(lat, lng);
    if (GeocercaUtil.estaDentroDeAlgunaZona(punto, _geocercas)) {
      final zona = GeocercaUtil.nombreZonaContenedora(punto, _geocercas);
      return zona != null ? 'Visita dentro de zona: $zona' : null;
    }
    return 'Aviso: la visita quedó fuera de las geocercas definidas.';
  }

  Future<void> actualizarClienteLocal(CarteraDiariaModel actualizado) async {
    final i = _clientes.indexWhere((c) => c.id == actualizado.id);
    if (i != -1) {
      _clientes[i] = actualizado;
      _construirMapa();
      notifyListeners();
    }
  }

  Future<void> recargar() async {
    if (_asesorid == null) return;
    await cargar(asesorid: _asesorid!, perfil: _perfil);
  }
}
