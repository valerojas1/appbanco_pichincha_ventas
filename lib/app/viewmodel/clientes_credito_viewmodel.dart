import 'package:flutter/material.dart';
import '../model/cliente_financiero_model.dart';
import '../services/cliente_credito_service.dart';

class ClientesCreditoViewModel extends ChangeNotifier {
  final ClienteCreditoService _service = ClienteCreditoService();

  List<ClienteFinancieroModel> _clientesActivos = [];
  List<ClienteFinancieroModel> _prospectos = [];
  bool _loadingActivos = false;
  bool _loadingProspectos = false;
  String? _errorActivos;
  String? _errorProspectos;

  List<ClienteFinancieroModel> get clientesActivos => _clientesActivos;
  List<ClienteFinancieroModel> get prospectos => _prospectos;
  bool get loadingActivos => _loadingActivos;
  bool get loadingProspectos => _loadingProspectos;
  String? get errorActivos => _errorActivos;
  String? get errorProspectos => _errorProspectos;

  int get totalActivos => _clientesActivos.length;
  int get totalProspectos => _prospectos.length;

  Future<void> cargarClientesActivos() async {
    _loadingActivos = true;
    _errorActivos = null;
    notifyListeners();

    try {
      _clientesActivos = await _service.getClientesActivos();
    } catch (_) {
      _errorActivos = 'No se pudieron cargar los clientes';
      _clientesActivos = [];
    }

    _loadingActivos = false;
    notifyListeners();
  }

  Future<void> cargarProspectos() async {
    _loadingProspectos = true;
    _errorProspectos = null;
    notifyListeners();

    try {
      _prospectos = await _service.getProspectosCredito();
    } catch (_) {
      _errorProspectos = 'No se pudieron cargar los prospectos';
      _prospectos = [];
    }

    _loadingProspectos = false;
    notifyListeners();
  }

  Future<void> cargarTodo() async {
    await Future.wait([cargarClientesActivos(), cargarProspectos()]);
  }
}
