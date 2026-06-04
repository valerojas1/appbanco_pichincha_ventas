import 'package:flutter/material.dart';
import '../core/network_service.dart';
import '../repositories/pending_sync_repository.dart';

class OfflineSyncViewModel extends ChangeNotifier {
  final NetworkService _red = NetworkService.instance;
  final PendingSyncRepository _sync = PendingSyncRepository();

  bool _sincronizando = false;
  int _pendientes = 0;
  String? _mensajeSync;
  bool _desdeCacheCartera = false;

  bool get modoOffline => _red.modoOffline;
  bool get hayConexion => _red.hayConexion;
  bool get sincronizando => _sincronizando;
  int get pendientes => _pendientes;
  String? get mensajeSync => _mensajeSync;
  bool get desdeCacheCartera => _desdeCacheCartera;

  Future<void> inicializar() async {
    await _red.inicializar();
    _red.addListener(_onRedCambio);
    await actualizarContadores();
  }

  void _onRedCambio() {
    notifyListeners();
    if (_red.hayConexion) {
      sincronizarPendientes();
    }
  }

  void marcarCarteraDesdeCache(bool v) {
    _desdeCacheCartera = v;
    notifyListeners();
  }

  Future<void> actualizarContadores() async {
    _pendientes = await _sync.contarPendientes();
    notifyListeners();
  }

  Future<void> sincronizarPendientes() async {
    if (!_red.hayConexion || _sincronizando) return;
    _sincronizando = true;
    _mensajeSync = null;
    notifyListeners();

    final n = await _sync.sincronizarTodo();
    _pendientes = await _sync.contarPendientes();
    if (n > 0) {
      _mensajeSync = 'Sincronizados $n registro(s)';
    }
    _sincronizando = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _red.removeListener(_onRedCambio);
    super.dispose();
  }
}
