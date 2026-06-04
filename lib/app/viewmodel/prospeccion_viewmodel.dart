import 'package:flutter/material.dart';
import '../model/campana_activa_model.dart';
import '../model/preevaluacion_resultado_model.dart';
import '../services/campana_activa_service.dart';
import '../services/preevaluacion_service.dart';

class ProspeccionViewModel extends ChangeNotifier {
  final PreEvaluacionService _preEvalService = PreEvaluacionService();
  final CampanaActivaService _campanaService = CampanaActivaService();

  List<CampanaActivaModel> _campanas = [];
  PreEvaluacionResultadoModel? _resultado;
  ProspectoSolicitudPrefill? _ultimoProspecto;
  bool _evaluando = false;
  bool _enCola = false;
  int _colaPendiente = 0;
  String? _error;

  List<CampanaActivaModel> get campanas => _campanas;
  PreEvaluacionResultadoModel? get resultado => _resultado;
  ProspectoSolicitudPrefill? get ultimoProspecto => _ultimoProspecto;
  bool get evaluando => _evaluando;
  bool get enCola => _enCola;
  int get colaPendiente => _colaPendiente;
  String? get error => _error;

  Future<void> cargarCampanas(String asesorid) async {
    _campanas = await _campanaService.listarVigentes(asesorid);
    notifyListeners();
  }

  Future<void> actualizarCola() async {
    _colaPendiente = await _preEvalService.getOfflineCount();
    notifyListeners();
  }

  Future<void> sincronizarCola() async {
    await _preEvalService.sincronizarPendientes();
    await actualizarCola();
  }

  Future<void> preEvaluar({
    required String asesorid,
    required String dni,
    required String nombres,
    required String tiponegocio,
    required double ingresos,
    required String destino,
    required double monto,
  }) async {
    _evaluando = true;
    _error = null;
    _resultado = null;
    _enCola = false;
    notifyListeners();

    _ultimoProspecto = ProspectoSolicitudPrefill(
      dni: dni,
      nombres: nombres,
      tiponegocio: tiponegocio,
      ingresos: ingresos,
      destino: destino,
      monto: monto,
    );

    final online = await _preEvalService.hayConexion;
    if (!online) {
      await _preEvalService.evaluar(
        asesorid: asesorid,
        dni: dni,
        nombres: nombres,
        tiponegocio: tiponegocio,
        ingresos: ingresos,
        destino: destino,
        monto: monto,
      );
      _enCola = true;
      _resultado = _preEvalService.evaluarLocal(
        ingresos: ingresos,
        monto: monto,
        destino: destino,
      );
      await actualizarCola();
      _evaluando = false;
      notifyListeners();
      return;
    }

    _resultado = await _preEvalService.evaluar(
      asesorid: asesorid,
      dni: dni,
      nombres: nombres,
      tiponegocio: tiponegocio,
      ingresos: ingresos,
      destino: destino,
      monto: monto,
    );

    if (_resultado == null) {
      _enCola = true;
      _resultado = _preEvalService.evaluarLocal(
        ingresos: ingresos,
        monto: monto,
        destino: destino,
      );
      await actualizarCola();
    }

    _evaluando = false;
    notifyListeners();
  }

  void limpiarResultado() {
    _resultado = null;
    _enCola = false;
    notifyListeners();
  }
}
