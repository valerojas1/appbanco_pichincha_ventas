import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class SyncLocalNotificationsService {
  SyncLocalNotificationsService._();
  static final SyncLocalNotificationsService instance =
      SyncLocalNotificationsService._();

  static const String _channelId = 'sync_nocturna';
  static const int _idCarteraManana = 9001;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> notificarCarteraMananaLista(int cantidadClientes) async {
    const android = AndroidNotificationDetails(
      _channelId,
      'Sincronización',
      importance: Importance.high,
      priority: Priority.high,
    );
    try {
      await _plugin.show(
        _idCarteraManana,
        'Cartera de mañana lista',
        'Tu cartera de mañana está lista — $cantidadClientes clientes',
        const NotificationDetails(
          android: android,
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('Notif sync: $e');
    }
  }
}
