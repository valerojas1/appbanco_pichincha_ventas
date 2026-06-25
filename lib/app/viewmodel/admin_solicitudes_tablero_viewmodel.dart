import 'package:flutter/material.dart';
import '../model/estado_solicitud.dart';
import '../model/solicitud_resumen_model.dart';
import '../services/admin_web_service.dart';

class AdminSolicitudesTableroViewModel extends ChangeNotifier {
  final AdminWebService _service = AdminWebService();

  TabSolicitud _tab = TabSolicitud.recibidas;
  List<SolicitudResumenModel> _lista = [];
  Map<TabSolicitud, int> _contadores = {};
  bool _cargando = false;

  TabSolicitud get tab => _tab;
  List<SolicitudResumenModel> get lista => _lista;
  Map<TabSolicitud, int> get contadores => _contadores;
  bool get cargando => _cargando;

  Future<void> iniciar() async {
    await refrescar();
  }

  void cambiarTab(TabSolicitud tab) {
    _tab = tab;
    notifyListeners();
    refrescar();
  }

  Future<void> refrescar() async {
    _cargando = true;
    notifyListeners();

    _contadores = await _service.contarSolicitudesPorTab();
    _lista = await _service.listarSolicitudesPorTab(tab: _tab);

    _cargando = false;
    notifyListeners();
  }
}
