import 'package:flutter/material.dart';
import '../model/estado_solicitud.dart';
import '../model/solicitud_resumen_model.dart';
import '../services/solicitud_estado_service.dart';

class SolicitudesTableroViewModel extends ChangeNotifier {
  final SolicitudEstadoService _service = SolicitudEstadoService();

  TabSolicitud _tab = TabSolicitud.enviadas;
  List<SolicitudResumenModel> _lista = [];
  Map<TabSolicitud, int> _contadores = {};
  bool _cargando = false;
  String? _asesorid;

  TabSolicitud get tab => _tab;
  List<SolicitudResumenModel> get lista => _lista;
  Map<TabSolicitud, int> get contadores => _contadores;
  bool get cargando => _cargando;

  Future<void> iniciar(String asesorid) async {
    _asesorid = asesorid;
    _service.suscribirCambios(
      asesorid: asesorid,
      onCambio: () => refrescar(),
    );
    await refrescar();
  }

  void cambiarTab(TabSolicitud tab) {
    _tab = tab;
    notifyListeners();
    refrescar();
  }

  Future<void> refrescar() async {
    final asesor = _asesorid;
    if (asesor == null) return;

    _cargando = true;
    notifyListeners();

    _contadores = await _service.contarPorTabs(asesor);
    _lista = await _service.listarPorTab(asesorid: asesor, tab: _tab);

    _cargando = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _service.cancelarSuscripcion();
    super.dispose();
  }
}
