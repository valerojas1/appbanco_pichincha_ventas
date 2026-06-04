import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Notificaciones locales para recordar compromisos de pago.
class CobranzaLocalNotificationsService {
  CobranzaLocalNotificationsService._();
  static final CobranzaLocalNotificationsService instance =
      CobranzaLocalNotificationsService._();

  static const String _channelId = 'cobranza_compromisos';
  static const String _channelName = 'Compromisos de cobranza';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _inicializado = false;

  Future<void> inicializar() async {
    if (_inicializado) return;

    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('America/Lima'));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (_) {},
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Recordatorios de compromisos de pago con clientes',
        importance: Importance.high,
      ),
    );

    await androidPlugin?.requestNotificationsPermission();

    _inicializado = true;
  }

  int _idNotificacion(String carteravencidaid, DateTime fecha) {
    return Object.hash(carteravencidaid, fecha.year, fecha.month, fecha.day) &
        0x7FFFFFFF;
  }

  Future<void> programarCompromisoPago({
    required String carteravencidaid,
    required String nombreCliente,
    required DateTime fechaCompromiso,
    required double monto,
  }) async {
    await inicializar();

    final scheduled = DateTime(
      fechaCompromiso.year,
      fechaCompromiso.month,
      fechaCompromiso.day,
      9,
      0,
    );
    if (scheduled.isBefore(DateTime.now())) return;

    final id = _idNotificacion(carteravencidaid, fechaCompromiso);
    await _plugin.cancel(id);

    final tzScheduled = tz.TZDateTime.from(scheduled, tz.local);

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
    );

    try {
      await _plugin.zonedSchedule(
        id,
        'Compromiso de pago',
        '$nombreCliente — S/ ${monto.toStringAsFixed(2)} hoy',
        tzScheduled,
        const NotificationDetails(
          android: androidDetails,
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('No se pudo programar notificación local: $e');
    }
  }

  Future<void> cancelarCompromiso(String carteravencidaid, DateTime fecha) async {
    await _plugin.cancel(_idNotificacion(carteravencidaid, fecha));
  }
}
