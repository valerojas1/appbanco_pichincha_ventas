import 'package:flutter/material.dart';
import '../model/cartera_vencida_model.dart';
import '../services/cartera_vencida_service.dart';

class CarteraVencidaViewModel extends ChangeNotifier {
  final CarteraVencidaService _service = CarteraVencidaService();

  List<CarteraVencidaModel> _lista = [];
  double _montoTotal = 0;
  bool _cargando = false;
  String? _error;
  List<String> _asesorIds = [];
  String _busqueda = '';

  List<CarteraVencidaModel> get lista => _lista;
  double get montoTotal => _montoTotal;
  bool get cargando => _cargando;
  String? get error => _error;

  List<CarteraVencidaModel> get listaFiltrada {
    final q = _busqueda.trim().toLowerCase();
    if (q.isEmpty) return _lista;
    return _lista.where((c) {
      return c.nombreCliente.toLowerCase().contains(q) ||
          c.dni.contains(q) ||
          c.numeroCredito.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> iniciar(List<String> asesorIds) async {
    _asesorIds = asesorIds;
    _service.suscribirCambios(
      asesorIds: asesorIds,
      onCambio: () => refrescar(),
    );
    await refrescar();
  }

  void setBusqueda(String value) {
    _busqueda = value;
    notifyListeners();
  }

  Future<void> refrescar() async {
    if (_asesorIds.isEmpty) return;

    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      _lista = await _service.listarPorAsesorIds(_asesorIds);
      _montoTotal = _lista.fold<double>(0, (s, c) => s + c.saldoVencido);
    } catch (e) {
      _error = 'No se pudo cargar la cartera: $e';
      _lista = [];
      _montoTotal = 0;
    }

    _cargando = false;
    notifyListeners();
  }

  void actualizarItemLocal(CarteraVencidaModel actualizado) {
    final idx = _lista.indexWhere((c) => c.id == actualizado.id);
    if (idx >= 0) {
      _lista[idx] = actualizado;
      _montoTotal = _lista.fold<double>(0, (s, c) => s + c.saldoVencido);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _service.cancelarSuscripcion();
    super.dispose();
  }
}
