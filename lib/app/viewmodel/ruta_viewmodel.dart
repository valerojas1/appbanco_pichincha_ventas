import 'package:flutter/material.dart';
import '../services/ruta_service.dart';
import '../model/ruta_planificada_model.dart';

class RutaViewModel extends ChangeNotifier {
  final RutaService _rutaService = RutaService();
  List<RutaPlanificadaModel> _rutas = [];
  bool _loading = false;

  List<RutaPlanificadaModel> get rutas => _rutas;
  bool get loading => _loading;

  Future<void> cargarRuta(String asesorid) async {
    _loading = true;
    notifyListeners();

    _rutas = await _rutaService.getRutaHoy(asesorid);

    _loading = false;
    notifyListeners();
  }

  Future<void> actualizarEstado(String rutaid, String estado) async {
    await _rutaService.actualizarEstadoVisita(rutaid, estado);
    await cargarRuta(_rutas.isNotEmpty ? _rutas.first.asesorid : '');
  }
}
