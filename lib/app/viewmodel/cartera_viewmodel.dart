import 'package:flutter/material.dart';
import '../services/ruta_service.dart';
import '../model/ruta_planificada_model.dart';

class CarteraViewModel extends ChangeNotifier {
  final RutaService _rutaService = RutaService();
  List<RutaPlanificadaModel> _rutas = [];
  bool _loading = false;

  List<RutaPlanificadaModel> get rutas => _rutas;
  bool get loading => _loading;
  int get totalVisitas => _rutas.length;
  int get visitados => _rutas.where((r) => r.estadovisita == 'visitado').length;
  int get pendientes => _rutas.where((r) => r.estadovisita == 'pendiente').length;

  Future<void> cargarRuta(String asesorid) async {
    _loading = true;
    notifyListeners();

    _rutas = await _rutaService.getRutaHoy(asesorid);

    _loading = false;
    notifyListeners();
  }

  Future<void> marcarVisitado(String rutaid) async {
    final success = await _rutaService.actualizarEstadoVisita(rutaid, 'visitado');
    if (success) {
      final index = _rutas.indexWhere((r) => r.rutaid == rutaid);
      if (index != -1) {
        _rutas[index] = RutaPlanificadaModel(
          rutaid: _rutas[index].rutaid,
          asesorid: _rutas[index].asesorid,
          clienteid: _rutas[index].clienteid,
          nombrecliente: _rutas[index].nombrecliente,
          direccion: _rutas[index].direccion,
          tipogestion: _rutas[index].tipogestion,
          estadovisita: 'visitado',
          fecharuta: _rutas[index].fecharuta,
          observaciones: _rutas[index].observaciones,
        );
        notifyListeners();
      }
    }
  }
}
