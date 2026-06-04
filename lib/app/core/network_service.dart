import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Estado de red para modo offline (Bloque 10).
class NetworkService extends ChangeNotifier {
  NetworkService._();
  static final NetworkService instance = NetworkService._();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _hayConexion = true;

  bool get hayConexion => _hayConexion;
  bool get modoOffline => !_hayConexion;

  Future<void> inicializar() async {
    _hayConexion = await _verificar();
    notifyListeners();
    _sub = _connectivity.onConnectivityChanged.listen((results) async {
      final antes = _hayConexion;
      _hayConexion = _tieneRed(results);
      if (antes != _hayConexion) notifyListeners();
    });
  }

  Future<bool> _verificar() async {
    final r = await _connectivity.checkConnectivity();
    return _tieneRed(r);
  }

  bool _tieneRed(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return !results.every((r) => r == ConnectivityResult.none);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
