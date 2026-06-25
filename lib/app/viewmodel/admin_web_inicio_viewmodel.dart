import 'package:flutter/material.dart';
import '../services/admin_web_service.dart';

class AdminWebInicioViewModel extends ChangeNotifier {
  final AdminWebService _service = AdminWebService();

  AdminInicioResumen? _resumen;
  bool _cargando = false;

  AdminInicioResumen? get resumen => _resumen;
  bool get cargando => _cargando;

  Future<void> cargar() async {
    _cargando = true;
    notifyListeners();

    _resumen = await _service.obtenerResumenInicio();

    _cargando = false;
    notifyListeners();
  }
}
