import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/auth_constants.dart';
import '../model/oficial_model.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';
import '../services/ficha_service.dart';
import '../services/visita_cartera_service.dart';
import '../services/preevaluacion_service.dart';
import '../services/solicitud_credito_service.dart';
import '../services/fcm_messaging_service.dart';
import '../workers/sincronizacion_nocturna_callback.dart';

enum AuthOficialState {
  initializing,
  unauthenticated,
  loading,
  authenticated,
  error,
}

class AuthOficialViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final SessionService _sessionService = SessionService();
  final FichaService _fichaService = FichaService();

  AuthOficialState _state = AuthOficialState.initializing;
  String _errorMessage = '';
  OficialModel? _oficial;
  Timer? _lockoutTimer;
  Duration? _lockoutRemaining;

  AuthOficialState get state => _state;
  String get errorMessage => _errorMessage;
  OficialModel? get oficial => _oficial;
  bool get isAuthenticated =>
      _state == AuthOficialState.authenticated && _oficial != null;
  Duration? get lockoutRemaining => _lockoutRemaining;
  bool get isLockedOut =>
      _lockoutRemaining != null && _lockoutRemaining!.inSeconds > 0;

  Future<void> initialize() async {
    _state = AuthOficialState.initializing;
    notifyListeners();

    await _refreshLockoutState();

    if (await _sessionService.isLockedOut()) {
      _state = AuthOficialState.unauthenticated;
      notifyListeners();
      return;
    }

    final session = _authService.currentSession;
    if (session != null) {
      if (await _sessionService.isSessionExpiredByInactivity()) {
        await _clearSessionInternal();
        _errorMessage =
            'Tu sesión expiró por inactividad (${AuthConstants.sessionInactivityLimit.inHours} h). Inicia sesión nuevamente.';
        _state = AuthOficialState.unauthenticated;
      } else {
        final cached = await _sessionService.readProfileJson();
        _oficial = cached != null
            ? OficialModel.fromJsonString(cached)
            : await _authService.restoreFromCurrentSession();

        if (_oficial != null) {
          await _sessionService.saveProfileJson(_oficial!.toJsonString());
          _state = AuthOficialState.authenticated;
          await _registrarFcm();
        } else {
          await _clearSessionInternal();
          _state = AuthOficialState.unauthenticated;
        }
      }
    } else {
      _state = AuthOficialState.unauthenticated;
    }

    notifyListeners();
  }

  Future<void> login(String codigoEmpleado, String password) async {
    await _refreshLockoutState();
    if (isLockedOut) {
      _errorMessage = 'Cuenta bloqueada. Espera el tiempo indicado.';
      _state = AuthOficialState.error;
      notifyListeners();
      return;
    }

    _state = AuthOficialState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final user =
          await _authService.loginWithCodigoEmpleado(codigoEmpleado, password);
      if (user != null) {
        await _sessionService.clearFailedAttempts();
        _oficial = user;
        await _sessionService.saveProfileJson(user.toJsonString());
        _state = AuthOficialState.authenticated;
        await _registrarFcm();
      } else {
        await _handleFailedLogin();
      }
    } on AuthApiException catch (e) {
      await _handleFailedLogin(message: _mapAuthError(e.message));
    } catch (_) {
      _state = AuthOficialState.error;
      _errorMessage = 'Error de conexión. Intenta nuevamente.';
    }

    await _refreshLockoutState();
    notifyListeners();
  }

  Future<void> _handleFailedLogin({String? message}) async {
    await _sessionService.recordFailedAttempt();
    await _refreshLockoutState();

    if (isLockedOut) {
      _state = AuthOficialState.error;
      _errorMessage =
          'Demasiados intentos fallidos. Cuenta bloqueada por ${AuthConstants.lockoutDuration.inMinutes} minutos.';
    } else {
      final attempts = await _sessionService.getFailedAttempts();
      final restantes = AuthConstants.maxLoginAttempts - attempts;
      _state = AuthOficialState.error;
      _errorMessage = message ??
          'Código o contraseña incorrectos. Te quedan $restantes intento(s).';
    }
  }

  String _mapAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid') || lower.contains('credentials')) {
      return 'Código de empleado o contraseña incorrectos';
    }
    return message;
  }

  Future<void> touchActivity() async {
    if (!isAuthenticated) return;
    await _sessionService.touchActivity();
  }

  Future<bool> checkInactivityExpiry() async {
    if (!isAuthenticated) return false;
    if (await _sessionService.isSessionExpiredByInactivity()) {
      _errorMessage =
          'Sesión cerrada por inactividad de ${AuthConstants.sessionInactivityLimit.inHours} horas.';
      await logout();
      return true;
    }
    return false;
  }

  /// Fichas + visitas + pre-evaluaciones pendientes de sincronizar.
  Future<int> pendingSyncCount() async {
    final fichas = await _fichaService.getOfflineCount();
    final visitas = await VisitaCarteraService().getOfflineCount();
    final preEval = await PreEvaluacionService().getOfflineCount();
    final solicitudes = await SolicitudCreditoService().contarPendientesEnvio();
    return fichas + visitas + preEval + solicitudes;
  }

  Future<void> logout() async {
    await _clearSessionInternal();
    _state = AuthOficialState.unauthenticated;
    notifyListeners();
  }

  Future<void> _clearSessionInternal() async {
    await _authService.signOut();
    await _sessionService.clearSession();
    await _fichaService.clearOfflineCache();
    await VisitaCarteraService().clearOfflineCache();
    await PreEvaluacionService().clearOfflineCache();
    await SolicitudCreditoService().limpiarColaEnvio();
    _oficial = null;
    _lockoutTimer?.cancel();
  }

  void resetLoginFormState() {
    if (_state == AuthOficialState.error) {
      _state = AuthOficialState.unauthenticated;
      _errorMessage = '';
      notifyListeners();
    }
  }

  Future<void> _registrarFcm() async {
    final o = _oficial;
    if (o == null) return;
    // Mismo id que usa solicitudescredito / vwperfilasesor
    final asesorid = o.asesorid.isNotEmpty ? o.asesorid : o.userid;
    if (asesorid.isEmpty) return;
    await FcmMessagingService.instance.inicializar(asesorid);
    try {
      await registrarSincronizacionNocturna();
    } catch (_) {}
  }

  Future<void> _refreshLockoutState() async {
    _lockoutRemaining = await _sessionService.remainingLockout();
    _lockoutTimer?.cancel();
    if (_lockoutRemaining != null && _lockoutRemaining!.inSeconds > 0) {
      _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
        _lockoutRemaining = await _sessionService.remainingLockout();
        if (_lockoutRemaining == null || _lockoutRemaining!.inSeconds <= 0) {
          await _sessionService.clearFailedAttempts();
          _lockoutTimer?.cancel();
        }
        notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }
}
