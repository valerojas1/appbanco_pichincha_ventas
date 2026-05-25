import 'package:flutter/material.dart';
import '../services/ficha_service.dart';

class FichaViewModel extends ChangeNotifier {
  final FichaService _fichaService = FichaService();
  bool _loading = false;
  bool _online = true;
  int _offlineCount = 0;

  bool get loading => _loading;
  bool get online => _online;
  int get offlineCount => _offlineCount;

  Future<bool> guardarFicha(Map<String, dynamic> data) async {
    _loading = true;
    notifyListeners();

    bool success;
    if (_online) {
      final result = await _fichaService.crearFicha(data);
      success = result != null;
      if (!success) {
        await _fichaService.guardarOffline(data);
        success = true;
      }
    } else {
      await _fichaService.guardarOffline(data);
      success = true;
    }

    await actualizarOfflineCount();

    _loading = false;
    notifyListeners();
    return success;
  }

  Future<void> sincronizar() async {
    _loading = true;
    notifyListeners();

    await _fichaService.sincronizarFichas();
    await actualizarOfflineCount();

    _loading = false;
    notifyListeners();
  }

  Future<void> actualizarOfflineCount() async {
    _offlineCount = await _fichaService.getOfflineCount();
    notifyListeners();
  }

  void setOnline(bool value) {
    _online = value;
    notifyListeners();
  }
}
