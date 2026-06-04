import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../core/cartera_mora_semaforo.dart';
import '../../model/accion_cobranza_enums.dart';
import '../../model/cartera_vencida_model.dart';
import '../../services/accion_cobranza_service.dart';
import '../../services/cartera_vencida_service.dart';
import '../../services/cobranza_local_notifications_service.dart';
import '../../ui/theme/app_theme.dart';
import '../../viewmodel/auth_oficial_viewmodel.dart';

class AccionCobranzaScreen extends StatefulWidget {
  final CarteraVencidaModel cartera;

  const AccionCobranzaScreen({super.key, required this.cartera});

  @override
  State<AccionCobranzaScreen> createState() => _AccionCobranzaScreenState();
}

class _AccionCobranzaScreenState extends State<AccionCobranzaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _obsController = TextEditingController();
  final _montoCompromisoController = TextEditingController();
  final _montoPagoController = TextEditingController();

  final _accionService = AccionCobranzaService();
  final _carteraService = CarteraVencidaService();

  TipoAccionCobranza _tipo = TipoAccionCobranza.visita;
  ResultadoAccionCobranza _resultado = ResultadoAccionCobranza.compromisoPago;
  DateTime? _fechaCompromiso;
  bool _enviando = false;
  late CarteraVencidaModel _cartera;

  @override
  void initState() {
    super.initState();
    _cartera = widget.cartera;
    _fechaCompromiso = DateTime.now().add(const Duration(days: 3));
  }

  @override
  void dispose() {
    _obsController.dispose();
    _montoCompromisoController.dispose();
    _montoPagoController.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaCompromiso ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.amarillo,
            surface: AppTheme.superficie,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _fechaCompromiso = picked);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final oficial = context.read<AuthOficialViewModel>().oficial;
    if (oficial == null) return;
    final asesorid =
        oficial.asesorid.isNotEmpty ? oficial.asesorid : oficial.userid;

    double? montoCompromiso;
    double? montoPago;
    DateTime? fechaCompromiso;

    if (_resultado.requiereCompromiso) {
      montoCompromiso = double.tryParse(_montoCompromisoController.text.trim());
      fechaCompromiso = _fechaCompromiso;
      if (montoCompromiso == null || montoCompromiso <= 0) {
        _mostrarError('Indique un monto de compromiso válido');
        return;
      }
      if (fechaCompromiso == null) {
        _mostrarError('Seleccione la fecha del compromiso');
        return;
      }
    }

    if (_resultado.requiereMontoPago) {
      montoPago = double.tryParse(_montoPagoController.text.trim());
      if (montoPago == null || montoPago <= 0) {
        _mostrarError('Indique el monto del pago parcial');
        return;
      }
      if (montoPago > _cartera.saldoVencido) {
        _mostrarError('El pago no puede superar el saldo vencido');
        return;
      }
    }

    setState(() => _enviando = true);

    Position? posicion;
    try {
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.whileInUse ||
          permiso == LocationPermission.always) {
        posicion = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 8),
          ),
        );
      }
    } catch (_) {}

    final registradoAt = DateTime.now();
    final ok = await _accionService.registrar(
      carteravencidaid: _cartera.id,
      asesorid: asesorid,
      tipo: _tipo,
      resultado: _resultado,
      observaciones: _obsController.text.trim(),
      latitud: posicion?.latitude,
      longitud: posicion?.longitude,
      registradoAt: registradoAt,
      montoCompromiso: montoCompromiso,
      fechaCompromiso: fechaCompromiso,
      montoPago: montoPago,
    );

    if (!ok) {
      if (mounted) {
        setState(() => _enviando = false);
        _mostrarError('No se pudo guardar la acción en Supabase');
      }
      return;
    }

    await _carteraService.marcarUltimaAccion(_cartera.id);

    if (_resultado == ResultadoAccionCobranza.pagoParcial && montoPago != null) {
      final nuevoSaldo = await _carteraService.aplicarPagoParcial(
        carteravencidaid: _cartera.id,
        montoPago: montoPago,
      );
      if (nuevoSaldo != null) {
        _cartera = CarteraVencidaModel(
          id: _cartera.id,
          asesorid: _cartera.asesorid,
          dni: _cartera.dni,
          nombreCliente: _cartera.nombreCliente,
          telefono: _cartera.telefono,
          numeroCredito: _cartera.numeroCredito,
          saldoVencido: nuevoSaldo,
          diasMora: _cartera.diasMora,
          fechaVencimiento: _cartera.fechaVencimiento,
          ultimaAccionAt: registradoAt,
        );
      }
    } else if (_resultado == ResultadoAccionCobranza.compromisoPago &&
        fechaCompromiso != null &&
        montoCompromiso != null) {
      await CobranzaLocalNotificationsService.instance.programarCompromisoPago(
        carteravencidaid: _cartera.id,
        nombreCliente: _cartera.nombreCliente,
        fechaCompromiso: fechaCompromiso,
        monto: montoCompromiso,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Recordatorio programado para ${fechaCompromiso.day}/'
              '${fechaCompromiso.month}/${fechaCompromiso.year} a las 9:00',
            ),
          ),
        );
      }
    } else {
      final actualizado = await _carteraService.obtenerPorId(_cartera.id);
      if (actualizado != null) _cartera = actualizado;
    }

    if (!mounted) return;
    setState(() => _enviando = false);
    Navigator.pop(context, _cartera);
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.orangeAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = CarteraMoraSemaforo.color(_cartera.diasMora);

    return Scaffold(
      backgroundColor: AppTheme.fondoOscuro,
      appBar: AppBar(
        title: const Text(
          'Acción de cobranza',
          style: TextStyle(
            color: AppTheme.amarillo,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
      body: _enviando
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppTheme.amarillo),
                  SizedBox(height: 12),
                  Text(
                    'Registrando acción y ubicación...',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _cartera.nombreCliente,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Saldo vencido: S/ ${_cartera.saldoVencido.toStringAsFixed(2)}',
                      style: const TextStyle(color: AppTheme.amarillo, fontSize: 13),
                    ),
                    Text(
                      CarteraMoraSemaforo.etiqueta(_cartera.diasMora),
                      style: TextStyle(color: color, fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Tipo de gestión',
                      style: TextStyle(color: AppTheme.amarillo, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<TipoAccionCobranza>(
                      segments: TipoAccionCobranza.values
                          .map(
                            (t) => ButtonSegment(
                              value: t,
                              label: Text(t.etiqueta, style: const TextStyle(fontSize: 11)),
                            ),
                          )
                          .toList(),
                      selected: {_tipo},
                      onSelectionChanged: (s) => setState(() => _tipo = s.first),
                      style: ButtonStyle(
                        foregroundColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return AppTheme.navy;
                          }
                          return Colors.white70;
                        }),
                        backgroundColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return AppTheme.amarillo;
                          }
                          return AppTheme.superficie;
                        }),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Resultado',
                      style: TextStyle(color: AppTheme.amarillo, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    ...ResultadoAccionCobranza.values.map(
                      (r) => RadioListTile<ResultadoAccionCobranza>(
                        title: Text(
                          r.etiqueta,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        value: r,
                        groupValue: _resultado,
                        activeColor: AppTheme.amarillo,
                        onChanged: (v) => setState(() => _resultado = v!),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    if (_resultado.requiereCompromiso) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _montoCompromisoController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                        ],
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Monto compromiso (S/)',
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          _fechaCompromiso == null
                              ? 'Fecha compromiso'
                              : 'Fecha: ${_fechaCompromiso!.day}/${_fechaCompromiso!.month}/${_fechaCompromiso!.year}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: const Icon(Icons.calendar_today, color: AppTheme.amarillo),
                        onTap: _elegirFecha,
                      ),
                    ],
                    if (_resultado.requiereMontoPago) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _montoPagoController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                        ],
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Monto pagado (máx. S/ ${_cartera.saldoVencido.toStringAsFixed(2)})',
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _obsController,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Observaciones',
                        alignLabelWithHint: true,
                      ),
                      validator: (v) =>
                          (v == null || v.trim().length < 3) ? 'Mínimo 3 caracteres' : null,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Se registrará GPS y hora al guardar',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _guardar,
                      child: const Text('REGISTRAR ACCIÓN'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
