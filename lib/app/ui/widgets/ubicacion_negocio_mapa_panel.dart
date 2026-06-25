import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/maps_config.dart';
import '../../services/geocoding_service.dart';
import '../../services/navegacion_externa_service.dart';
import '../../ui/theme/app_theme.dart';

/// Muestra mapa, dirección geocodificada y acciones de navegación para el local del negocio.
class UbicacionNegocioMapaPanel extends StatefulWidget {
  final double latitud;
  final double longitud;
  final String? direccionTexto;
  final String? nombreNegocio;
  final bool compacto;

  const UbicacionNegocioMapaPanel({
    super.key,
    required this.latitud,
    required this.longitud,
    this.direccionTexto,
    this.nombreNegocio,
    this.compacto = false,
  });

  @override
  State<UbicacionNegocioMapaPanel> createState() =>
      _UbicacionNegocioMapaPanelState();
}

class _UbicacionNegocioMapaPanelState extends State<UbicacionNegocioMapaPanel> {
  final _geocoding = GeocodingService();
  final _navegacion = NavegacionExternaService();
  final _mapController = MapController();

  String? _direccionGeocodificada;
  bool _cargandoDireccion = true;

  @override
  void initState() {
    super.initState();
    _resolverDireccion();
  }

  Future<void> _resolverDireccion() async {
    final dir = await _geocoding.direccionDesdeCoordenadas(
      widget.latitud,
      widget.longitud,
    );
    if (mounted) {
      setState(() {
        _direccionGeocodificada = dir;
        _cargandoDireccion = false;
      });
    }
  }

  Future<void> _abrirNavegacion() async {
    final ok = await _navegacion.abrirNavegacion(
      latitud: widget.latitud,
      longitud: widget.longitud,
      etiqueta: widget.nombreNegocio ?? widget.direccionTexto,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir la app de mapas'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final punto = LatLng(widget.latitud, widget.longitud);
    final alturaMapa = widget.compacto ? 140.0 : 200.0;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.amarillo.withValues(alpha: 0.35)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: alturaMapa,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: punto,
                initialZoom: 16,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: MapsConfig.osmTileUrl,
                  userAgentPackageName: MapsConfig.osmUserAgent,
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: punto,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.store,
                        color: AppTheme.amarillo,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ubicación del negocio',
                  style: TextStyle(
                    color: AppTheme.amarillo,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${widget.latitud.toStringAsFixed(6)}, '
                  '${widget.longitud.toStringAsFixed(6)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                if (widget.direccionTexto != null &&
                    widget.direccionTexto!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Dirección declarada por el cliente',
                    style: TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                  Text(
                    widget.direccionTexto!.trim(),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 8),
                const Text(
                  'Dirección cotejada (geocodificación inversa)',
                  style: TextStyle(color: Colors.white54, fontSize: 10),
                ),
                Text(
                  _cargandoDireccion
                      ? 'Resolviendo dirección...'
                      : (_direccionGeocodificada ??
                          'No se pudo obtener la dirección desde las coordenadas'),
                  style: TextStyle(
                    color: _direccionGeocodificada != null
                        ? AppTheme.verdePendiente
                        : Colors.white54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _abrirNavegacion,
                    icon: const Icon(Icons.navigation_outlined, size: 18),
                    label: const Text('Ir con mapas / Waze'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.amarillo,
                      side: BorderSide(
                        color: AppTheme.amarillo.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
