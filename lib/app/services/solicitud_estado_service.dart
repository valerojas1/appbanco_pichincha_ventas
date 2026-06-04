import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/estado_solicitud.dart';
import '../model/solicitud_resumen_model.dart';

class SolicitudEstadoService {
  final SupabaseClient _client = Supabase.instance.client;

  RealtimeChannel? _canal;

  Future<List<SolicitudResumenModel>> listarPorTab({
    required String asesorid,
    required TabSolicitud tab,
  }) async {
    try {
      final rows = await _client
          .from('solicitudescredito')
          .select(
            'id, nombres, apellidos, monto, estado, numeroexpediente, '
            'analistaasignado, fechaeenvio, createdat',
          )
          .eq('asesorid', asesorid)
          .inFilter('estado', tab.estadosDb)
          .order('fechaeenvio', ascending: false)
          .limit(50);

      return (rows as List)
          .map((r) => SolicitudResumenModel.fromJson(
                Map<String, dynamic>.from(r as Map),
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<Map<TabSolicitud, int>> contarPorTabs(String asesorid) async {
    final map = <TabSolicitud, int>{};
    for (final tab in TabSolicitud.values) {
      try {
        final rows = await _client
            .from('solicitudescredito')
            .select('id')
            .eq('asesorid', asesorid)
            .inFilter('estado', tab.estadosDb);
        map[tab] = (rows as List).length;
      } catch (_) {
        map[tab] = 0;
      }
    }
    return map;
  }

  Future<SolicitudDetalleModel?> obtenerDetalle(String solicitudId) async {
    try {
      final row = await _client
          .from('solicitudescredito')
          .select()
          .eq('id', solicitudId)
          .maybeSingle();
      if (row == null) return null;
      return SolicitudDetalleModel.fromJson(
        Map<String, dynamic>.from(row),
      );
    } catch (_) {
      return null;
    }
  }

  void suscribirCambios({
    required String asesorid,
    required void Function() onCambio,
  }) {
    _canal?.unsubscribe();
    _canal = _client
        .channel('solicitudes_asesor_$asesorid')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'solicitudescredito',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'asesorid',
            value: asesorid,
          ),
          callback: (_) => onCambio(),
        )
        .subscribe();
  }

  void cancelarSuscripcion() {
    _canal?.unsubscribe();
    _canal = null;
  }
}
