import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../model/cartera_diaria_model.dart';
import '../../ui/theme/app_theme.dart';
import '../../services/cartera_diaria_service.dart';
import '../../services/geocerca_service.dart';
import '../../services/geocoding_service.dart';
import '../../core/geocerca_util.dart';
import '../../viewmodel/cartera_viewmodel.dart';
import '../../viewmodel/ficha_viewmodel.dart';
import '../../viewmodel/auth_oficial_viewmodel.dart';
import '../../viewmodel/ruta_mapa_viewmodel.dart';
import 'package:latlong2/latlong.dart';
import 'widgets/resultado_visita_sheet.dart';

class FichaCarteraScreen extends StatefulWidget {
  final CarteraDiariaModel cartera;

  const FichaCarteraScreen({super.key, required this.cartera});

  @override
  State<FichaCarteraScreen> createState() => _FichaCarteraScreenState();
}

class _FichaCarteraScreenState extends State<FichaCarteraScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _dniController;
  late final TextEditingController _direccionController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _tipoNegocioController;
  late final TextEditingController _ingresoController;
  late final TextEditingController _observacionesController;
  bool _enviando = false;
  bool _salidaConfirmada = false;
  double? _latCapturada;
  double? _lngCapturada;
  final _carteraService = CarteraDiariaService();
  final _geocodingService = GeocodingService();
  final _geocercaService = GeocercaService();

  @override
  void initState() {
    super.initState();
    final c = widget.cartera;
    _nombreController = TextEditingController(text: c.nombrecliente);
    _dniController = TextEditingController(text: c.documento);
    _direccionController = TextEditingController(text: c.direccion ?? '');
    _telefonoController = TextEditingController(text: c.telefono ?? '');
    _tipoNegocioController = TextEditingController(text: c.tipogestion);
    _ingresoController = TextEditingController(text: c.monto.toStringAsFixed(0));
    _observacionesController = TextEditingController();
    _latCapturada = c.latitud;
    _lngCapturada = c.longitud;
  }

  Future<void> _capturarUbicacionNegocio() async {
    setState(() => _enviando = true);
    try {
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      _latCapturada = pos.latitude;
      _lngCapturada = pos.longitude;

      final direccion = await _geocodingService.direccionDesdeCoordenadas(
        pos.latitude,
        pos.longitude,
      );
      if (direccion != null && direccion.isNotEmpty) {
        _direccionController.text = direccion;
      }

      final ok = await _carteraService.actualizarCoordenadas(
        carteraid: widget.cartera.id,
        latitud: pos.latitude,
        longitud: pos.longitude,
        direccion: _direccionController.text.trim(),
      );

      if (ok && mounted) {
        final actualizado = widget.cartera.copyWith(
          latitud: pos.latitude,
          longitud: pos.longitude,
          direccion: _direccionController.text.trim(),
        );
        context.read<CarteraViewModel>().actualizarCoordenadasLocal(
              widget.cartera.id,
              latitud: pos.latitude,
              longitud: pos.longitude,
              direccion: _direccionController.text.trim(),
            );
        context.read<RutaMapaViewModel>().actualizarClienteLocal(actualizado);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok
                  ? 'Coordenadas del negocio actualizadas'
                  : 'GPS capturado localmente; error al sincronizar',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo obtener la ubicación'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
    setState(() => _enviando = false);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _dniController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _tipoNegocioController.dispose();
    _ingresoController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<bool> _onSalir() async {
    if (_salidaConfirmada) return true;

    final data = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.navyOscuro,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ResultadoVisitaSheet(nombreCliente: widget.cartera.nombrecliente),
    );

    if (data == null) return false;

    setState(() => _enviando = true);

    Position? posicion;
    try {
      final permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (_) {}

    if (!mounted) return false;

    if (posicion != null) {
      final zonas = await _geocercaService.listarActivas();
      final msg = GeocercaUtil.estaDentroDeAlgunaZona(
            LatLng(posicion.latitude, posicion.longitude),
            zonas,
          )
          ? null
          : 'Aviso: la visita quedó fuera de las geocercas definidas.';
      if (msg != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.orangeAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }

    final carteraVm = context.read<CarteraViewModel>();
    final online = await carteraVm.registrarResultadoVisita(
      carteraid: widget.cartera.id,
      resultado: data['resultado']!,
      observacion: data['observacion'] ?? '',
      latitud: posicion?.latitude,
      longitud: posicion?.longitude,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            online
                ? 'Visita registrada en Supabase'
                : 'Visita guardada en cola offline',
          ),
        ),
      );
    }

    _salidaConfirmada = true;
    setState(() => _enviando = false);
    return true;
  }

  Future<void> _guardarFicha() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);

    final oficial = context.read<AuthOficialViewModel>().oficial;
    final data = {
      'asesorid': oficial?.asesorid ?? oficial?.userid ?? '',
      'prospectonombre': _nombreController.text.trim(),
      'prospectodni': _dniController.text.trim(),
      'prospectotelefono': _telefonoController.text.trim(),
      'negociorubro': _tipoNegocioController.text.trim(),
      'ingresodeclarado': double.tryParse(_ingresoController.text.trim()) ?? 0,
      'observaciones': _observacionesController.text.trim(),
      'estadoficha': 'completada',
      'carteraid': widget.cartera.id,
    };

    final ok = await context.read<FichaViewModel>().guardarFicha(data);
    setState(() => _enviando = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Ficha guardada' : 'Error al guardar ficha'),
          backgroundColor: ok ? null : Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final salir = await _onSalir();
        if (!context.mounted) return;
        if (salir) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: AppTheme.fondoOscuro,
        appBar: AppBar(
          title: const Text(
            'Ficha de campo',
            style: TextStyle(
              color: AppTheme.amarillo,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final salir = await _onSalir();
              if (!mounted) return;
              if (salir) Navigator.pop(context);
            },
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nombreController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Cliente',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _dniController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Documento',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.superficie,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.amarillo.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Ubicación del negocio',
                        style: TextStyle(
                          color: AppTheme.amarillo,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _latCapturada != null
                            ? 'Lat: ${_latCapturada!.toStringAsFixed(5)}, Lng: ${_lngCapturada!.toStringAsFixed(5)}'
                            : 'Sin coordenadas registradas',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _enviando ? null : _capturarUbicacionNegocio,
                        icon: const Icon(Icons.my_location, size: 18),
                        label: const Text('Capturar GPS y geocodificar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.amarillo,
                          side: const BorderSide(color: AppTheme.amarillo),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _direccionController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Dirección (editable)',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _telefonoController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tipoNegocioController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Tipo gestión / rubro',
                    prefixIcon: Icon(Icons.store_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ingresoController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Monto referencia (S/)',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _observacionesController,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Notas de ficha',
                    prefixIcon: Icon(Icons.notes),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _enviando ? null : _guardarFicha,
                    child: _enviando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.navy,
                            ),
                          )
                        : const Text('GUARDAR FICHA'),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Al volver atrás debes registrar el resultado de la visita.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
