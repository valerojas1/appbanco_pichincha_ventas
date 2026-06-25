import 'package:flutter/material.dart';
import '../model/solicitud_credito_data.dart';
import '../services/solicitud_bandeja_cliente_service.dart';

class BandejaSolicitudesClienteViewModel extends ChangeNotifier {
  final SolicitudBandejaClienteService _service = SolicitudBandejaClienteService();

  List<SolicitudBandejaClienteResumen> _pendientes = [];
  List<SolicitudBandejaClienteResumen> _enAtencion = [];
  int _contadorPendientes = 0;
  bool _cargando = false;
  bool _procesando = false;
  String? _error;

  List<SolicitudBandejaClienteResumen> get pendientes => _pendientes;
  List<SolicitudBandejaClienteResumen> get enAtencion => _enAtencion;
  int get contadorPendientes => _contadorPendientes;
  bool get cargando => _cargando;
  bool get procesando => _procesando;
  String? get error => _error;

  Future<void> cargar(String asesorid) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    final pendientesRes = await _service.listarPendientes();
    final enAtencionRes = await _service.listarEnAtencion(asesorid: asesorid);
    final contadorRes = await _service.contarPendientes();

    _pendientes = pendientesRes.items;
    _enAtencion = enAtencionRes.items;
    _contadorPendientes = contadorRes.count;

    final errores = [
      pendientesRes.error,
      enAtencionRes.error,
      contadorRes.error,
    ].whereType<String>().toList();

    if (errores.isNotEmpty) {
      _error = errores.first;
    }

    _cargando = false;
    notifyListeners();
  }

  Future<SolicitudCreditoData?> tomar({
    required String solicitudId,
    required String asesorid,
  }) async {
    _procesando = true;
    _error = null;
    notifyListeners();

    final r = await _service.tomarSolicitud(
      solicitudId: solicitudId,
      asesorid: asesorid,
    );

    _procesando = false;
    if (!r.ok) {
      _error = r.error;
      notifyListeners();
      return null;
    }

    await cargar(asesorid);
    return r.datos;
  }

  Future<SolicitudCreditoData?> continuar({
    required String solicitudId,
    required String asesorid,
  }) async {
    _procesando = true;
    notifyListeners();
    final datos = await _service.cargarParaContinuar(
      solicitudId: solicitudId,
      asesorid: asesorid,
    );
    _procesando = false;
    notifyListeners();
    return datos;
  }
}
