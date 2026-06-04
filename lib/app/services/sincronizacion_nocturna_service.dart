import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/asesor_id_util.dart';
import '../model/oficial_model.dart';
import 'app_local_database.dart';
import 'cartera_diaria_service.dart';
import 'ficha_cliente_service.dart';
import 'session_service.dart';
import 'sync_local_notifications_service.dart';

/// Descarga nocturna: cartera mañana, fichas, movimientos 3 meses, preaprobados.
class SincronizacionNocturnaService {
  final SupabaseClient _client = Supabase.instance.client;
  final AppLocalDatabase _local = AppLocalDatabase.instance;
  final CarteraDiariaService _carteraRemoto = CarteraDiariaService();
  final FichaClienteService _fichaService = FichaClienteService();

  static Future<void> ejecutarDesdeBackground() async {
    final perfilJson = await SessionService().readProfileJson();
    if (perfilJson == null) return;
    final oficial = OficialModel.fromJsonString(perfilJson);
    if (oficial == null) return;
    final ids = AsesorIdUtil.idsConsulta(oficial);
    if (ids.isEmpty) return;
    await SincronizacionNocturnaService().ejecutar(ids.first);
  }

  Future<int> ejecutar(String asesorid) async {
    final manana = DateTime.now()
        .add(const Duration(days: 1))
        .toIso8601String()
        .split('T')
        .first;

    var clientesManana = 0;

    try {
      final cartera = await _client
          .from('carteradiaria')
          .select()
          .eq('asesorid', asesorid)
          .eq('fechaasignacion', manana);

      final lista = (cartera as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      clientesManana = lista.length;

      await _local.guardarCarteraCache(
        asesorid: asesorid,
        fecha: manana,
        items: lista,
      );

      await _fichaService.sincronizarCarteraAsesor(asesorid);

      final hace3Meses = DateTime.now()
          .subtract(const Duration(days: 90))
          .toIso8601String();

      try {
        final movs = await _client
            .from('movimientoscliente')
            .select()
            .eq('asesorid', asesorid)
            .gte('fecha', hace3Meses)
            .limit(500);
        final porCliente = <String, List<Map<String, dynamic>>>{};
        for (final m in movs as List) {
          final map = Map<String, dynamic>.from(m as Map);
          final cid = map['clienteid']?.toString() ?? 'sin_id';
          porCliente.putIfAbsent(cid, () => []).add(map);
        }
        for (final e in porCliente.entries) {
          await _local.guardarMovimientosCliente(
            clienteid: e.key,
            asesorid: asesorid,
            movimientos: e.value,
          );
        }
      } catch (_) {}

      try {
        final pre = await _client
            .from('preaprobados')
            .select()
            .eq('asesorid', asesorid)
            .eq('vigente', true);
        await _local.guardarPreaprobados(
          asesorid: asesorid,
          items: (pre as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList(),
        );
      } catch (_) {}

      final hoy = await _carteraRemoto.getCarteraHoy(asesorid);
      if (hoy.isNotEmpty) {
        await _local.guardarCarteraCache(
          asesorid: asesorid,
          fecha: DateTime.now().toIso8601String().split('T').first,
          items: hoy
              .map(
                (c) => {
                  'id': c.id,
                  'asesorid': c.asesorid,
                  'nombrecliente': c.nombrecliente,
                  'documento': c.documento,
                  'tipogestion': c.tipogestion,
                  'monto': c.monto,
                  'prioridad': c.prioridadServidor,
                  'fechaasignacion': c.fechaasignacion,
                  'estadovisita': c.estadovisita,
                  'moraactiva': c.moraactiva,
                  'diasenmora': c.diasenmora,
                  'direccion': c.direccion,
                  'telefono': c.telefono,
                  'latitud': c.latitud,
                  'longitud': c.longitud,
                  'clienteid': c.clienteid,
                },
              )
              .toList(),
        );
      }

      await _local.setMeta(
        'ultima_sync_nocturna',
        DateTime.now().toIso8601String(),
      );

      await SyncLocalNotificationsService.instance
          .notificarCarteraMananaLista(clientesManana);
    } catch (e) {
      debugPrint('Sync nocturna: $e');
    }

    return clientesManana;
  }
}
