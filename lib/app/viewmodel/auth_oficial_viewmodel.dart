import 'package:flutter/material.dart';

enum AuthOficialState { idle, loading, success, error }

class AuthOficialViewModel extends ChangeNotifier {
  AuthOficialState _state = AuthOficialState.idle;
  String _errorMessage = '';

  AuthOficialState get state => _state;
  String get errorMessage => _errorMessage;

  // Credenciales hardcodeadas para S9
  static const String _codigoValido = 'OFC-001';
  static const String _passwordValida = 'oficial123';

  Future<void> login(String codigo, String password) async {
    _state = AuthOficialState.loading;
    _errorMessage = '';
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    if (codigo == _codigoValido && password == _passwordValida) {
      _state = AuthOficialState.success;
    } else {
      _state = AuthOficialState.error;
      _errorMessage = 'Código o contraseña incorrectos';
    }
    notifyListeners();
  }

  void reset() {
    _state = AuthOficialState.idle;
    _errorMessage = '';
    notifyListeners();
  }
}