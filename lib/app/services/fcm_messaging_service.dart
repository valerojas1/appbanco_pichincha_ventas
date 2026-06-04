import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/app_navigator.dart';
import '../navigation/app_router.dart';
import '../view/home/solicitud_detalle_screen.dart';
import 'fcm_token_service.dart';

/// Registra FCM, guarda token en Supabase y maneja notificaciones.
class FcmMessagingService {
  FcmMessagingService._();
  static final FcmMessagingService instance = FcmMessagingService._();

  final FcmTokenService _tokenService = FcmTokenService();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  String? _ultimoToken;

  String? get ultimoToken => _ultimoToken;

  Future<void> inicializar(String asesorid) async {
    if (asesorid.isEmpty) return;

    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (kDebugMode) {
        debugPrint('FCM permiso: ${settings.authorizationStatus}');
      }

      final token = await _messaging.getToken();
      if (token == null) {
        if (kDebugMode) {
          debugPrint('FCM: getToken() devolvió null — no se guarda en Supabase');
        }
        return;
      }

      _ultimoToken = token;
      final guardado = await _tokenService.guardarToken(
        asesorid: asesorid,
        token: token,
      );
      if (kDebugMode) {
        debugPrint('');
        debugPrint('========== FCM TOKEN (copiar para prueba en Firebase) ==========');
        debugPrint(token);
        debugPrint(
          guardado
              ? 'Supabase: guardado en asesores_fcmtokens'
              : 'Supabase: NO guardado (ver error arriba)',
        );
        debugPrint('================================================================');
        debugPrint('');
      }

      _messaging.onTokenRefresh.listen((nuevo) async {
        _ultimoToken = nuevo;
        await _tokenService.guardarToken(asesorid: asesorid, token: nuevo);
      });

      FirebaseMessaging.onMessage.listen(_mostrarMensajePrimerPlano);
      FirebaseMessaging.onMessageOpenedApp.listen(_abrirDesdeNotificacion);

      final initial = await _messaging.getInitialMessage();
      if (initial != null) {
        _abrirDesdeNotificacion(initial);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FCM init error: $e');
      }
    }
  }

  void _mostrarMensajePrimerPlano(RemoteMessage message) {
    final ctx = appNavigatorKey.currentContext;
    if (ctx == null) return;

    final titulo = message.notification?.title ?? 'Pichincha Ventas';
    final cuerpo = message.notification?.body ?? '';
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text('$titulo${cuerpo.isNotEmpty ? ': $cuerpo' : ''}'),
        duration: const Duration(seconds: 5),
        action: message.data['solicitud_id'] != null
            ? SnackBarAction(
                label: 'Ver',
                onPressed: () => _navegarASolicitud(
                  message.data['solicitud_id']!.toString(),
                ),
              )
            : null,
      ),
    );
  }

  void _abrirDesdeNotificacion(RemoteMessage message) {
    final id = message.data['solicitud_id']?.toString();
    if (id != null && id.isNotEmpty) {
      _navegarASolicitud(id);
    }
  }

  void _navegarASolicitud(String solicitudId) {
    final nav = appNavigatorKey.currentState;
    if (nav == null) return;
    nav.push(
      MaterialPageRoute(
        builder: (_) => SolicitudDetalleScreen(solicitudId: solicitudId),
        settings: RouteSettings(name: AppRouter.solicitudDetalle),
      ),
    );
  }
}
