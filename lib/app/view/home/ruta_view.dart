import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/maps_config.dart';
import '../../model/cartera_diaria_model.dart';
import '../../viewmodel/auth_oficial_viewmodel.dart';
import '../../viewmodel/ruta_mapa_viewmodel.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/oficial_scaffold.dart';
import 'ficha_cliente_screen.dart';
import 'ficha_cartera_screen.dart';
import 'widgets/ficha_rapida_sheet.dart';

class RutaView extends StatefulWidget {
  final bool embedded;

  const RutaView({super.key, this.embedded = false});

  @override
  State<RutaView> createState() => _RutaViewState();
}

class _RutaViewState extends State<RutaView> {
  final MapController _mapController = MapController();
  String? _ultimoSheetClienteId;
  bool _estabaCargando = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  void _cargar() {
    final oficial = context.read<AuthOficialViewModel>().oficial;
    if (oficial != null) {
      context.read<RutaMapaViewModel>().cargar(
            asesorid: oficial.asesorid,
            perfil: oficial.perfil,
          );
    }
  }

  void _mostrarFichaRapida(RutaMapaViewModel vm) {
    final cliente = vm.clienteSeleccionado;
    if (cliente == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FichaRapidaSheet(
        cliente: cliente,
        onCerrar: () {
          Navigator.pop(ctx);
          _ultimoSheetClienteId = null;
          vm.limpiarSeleccion();
        },
        onNavegar: () async {
          Navigator.pop(ctx);
          final ok = await vm.navegarA(cliente);
          if (!mounted) return;
          if (!ok) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se pudo abrir la app de navegación'),
              ),
            );
          }
        },
        onFichaCampo: () {
          Navigator.pop(ctx);
          _ultimoSheetClienteId = null;
          vm.limpiarSeleccion();
          _abrirFichaCampo(cliente);
        },
        onVerFichaCompleta: () {
          Navigator.pop(ctx);
          vm.limpiarSeleccion();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FichaClienteScreen(
                args: FichaClienteArgs.fromCartera(cliente),
              ),
            ),
          ).then((_) => _cargar());
        },
      ),
    );
  }

  void _abrirFichaCampo(CarteraDiariaModel cliente) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FichaCarteraScreen(cartera: cliente),
      ),
    ).then((_) {
      if (!mounted) return;
      _cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RutaMapaViewModel>();
    final seleccionado = vm.clienteSeleccionado;
    if (_estabaCargando && !vm.loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ajustarCamara(vm);
      });
    }
    _estabaCargando = vm.loading;
    if (seleccionado != null && seleccionado.id != _ultimoSheetClienteId) {
      _ultimoSheetClienteId = seleccionado.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || vm.clienteSeleccionado == null) return;
        _mostrarFichaRapida(vm);
      });
    }

    return OficialScaffold(
      embedded: widget.embedded,
      title: 'Planificación de Ruta',
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: vm.centroMapa,
                initialZoom: 14,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: MapsConfig.osmTileUrl,
                  userAgentPackageName: MapsConfig.osmUserAgent,
                ),
                if (vm.poligonos.isNotEmpty)
                  PolygonLayer(polygons: vm.poligonos),
                if (vm.polilineas.isNotEmpty)
                  PolylineLayer(polylines: vm.polilineas),
                MarkerLayer(markers: vm.marcadores),
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
          ),
          if (vm.loading)
            ColoredBox(
              color: AppTheme.fondoOscuro.withValues(alpha: 0.85),
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.amarillo),
              ),
            ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _LeyendaMapa(
              conCoordenadas: vm.conCoordenadas,
              total: vm.clientes.length,
              mostrarGeocercas: vm.mostrarGeocercas,
            ),
          ),
          if (vm.posicionActual != null)
            Positioned(
              right: 16,
              bottom: 88,
              child: FloatingActionButton.small(
                heroTag: 'ruta_mi_ubicacion',
                backgroundColor: AppTheme.superficie,
                foregroundColor: AppTheme.amarillo,
                onPressed: () => _centrarEnUbicacion(vm.posicionActual!),
                child: const Icon(Icons.my_location),
              ),
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _BarraAcciones(
              optimizando: vm.optimizando,
              onOptimizar: () async {
                await vm.optimizarRuta();
                _ajustarCamara(vm);
              },
              onNavegarSiguiente: () async {
                if (vm.ordenOptimizado.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Primero optimiza la ruta',
                      ),
                    ),
                  );
                  return;
                }
                final id = vm.ordenOptimizado.first;
                final cliente = vm.clientes
                    .where((c) => c.id == id)
                    .firstOrNull;
                if (cliente != null) {
                  await vm.navegarA(cliente);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _centrarEnUbicacion(LatLng punto) {
    _mapController.move(punto, 15);
  }

  void _ajustarCamara(RutaMapaViewModel vm) {
    final puntos = vm.puntosParaEncuadre();
    if (puntos.isEmpty) return;

    if (puntos.length == 1) {
      _mapController.move(puntos.first, 15);
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
        padding: const EdgeInsets.all(48),
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}

class _LeyendaMapa extends StatelessWidget {
  final int conCoordenadas;
  final int total;
  final bool mostrarGeocercas;

  const _LeyendaMapa({
    required this.conCoordenadas,
    required this.total,
    required this.mostrarGeocercas,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.superficie.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.amarillo.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$conCoordenadas / $total con ubicación en mapa',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(height: 4),
          const Text(
            'Mapa: OpenStreetMap (sin costo)',
            style: TextStyle(color: Colors.white38, fontSize: 10),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 10,
            runSpacing: 4,
            children: const [
              _LeyendaItem(color: Colors.red, texto: 'ALTA'),
              _LeyendaItem(color: Colors.amber, texto: 'MEDIA'),
              _LeyendaItem(color: Colors.green, texto: 'NORMAL'),
              _LeyendaItem(color: Colors.grey, texto: 'Visitado'),
            ],
          ),
          if (mostrarGeocercas)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Geocercas visibles (supervisor/admin)',
                style: TextStyle(color: AppTheme.amarillo, fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }
}

class _LeyendaItem extends StatelessWidget {
  final Color color;
  final String texto;

  const _LeyendaItem({required this.color, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(texto, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }
}

class _BarraAcciones extends StatelessWidget {
  final bool optimizando;
  final VoidCallback onOptimizar;
  final VoidCallback onNavegarSiguiente;

  const _BarraAcciones({
    required this.optimizando,
    required this.onOptimizar,
    required this.onNavegarSiguiente,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: optimizando ? null : onOptimizar,
            icon: optimizando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.navy,
                    ),
                  )
                : const Icon(Icons.route, size: 20),
            label: const Text('Optimizar ruta'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onNavegarSiguiente,
            icon: const Icon(Icons.navigation, size: 20),
            label: const Text('Navegar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.amarillo,
              side: const BorderSide(color: AppTheme.amarillo),
              backgroundColor: AppTheme.navyOscuro.withValues(alpha: 0.9),
            ),
          ),
        ),
      ],
    );
  }
}
