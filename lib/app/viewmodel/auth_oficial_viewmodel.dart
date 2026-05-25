import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../model/oficial_model.dart';

enum AuthOficialState { idle, loading, success, error }

class AuthOficialViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  AuthOficialState _state = AuthOficialState.idle;
  String _errorMessage = '';
  OficialModel? _oficial;

  AuthOficialState get state => _state;
  String get errorMessage => _errorMessage;
  OficialModel? get oficial => _oficial;

  Future<void> login(String dni, String password) async {
    _state = AuthOficialState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final user = await _authService.login(dni, password);
      if (user != null) {
        _oficial = user;
        _state = AuthOficialState.success;
      } else {
        _state = AuthOficialState.error;
        _errorMessage = 'DNI o contraseña incorrectos';
      }
    } catch (e) {
      _state = AuthOficialState.error;
      _errorMessage = 'Error de conexión';
    }
    notifyListeners();
  }

  void reset() {
    _state = AuthOficialState.idle;
    _errorMessage = '';
    notifyListeners();
  }

  void logout() {
    _oficial = null;
    _state = AuthOficialState.idle;
    notifyListeners();
  }
}
