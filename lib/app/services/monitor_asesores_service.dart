import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/asesor_monitor_model.dart';

class MonitorAsesoresService {
  final SupabaseClient _client = Supabase.instance.client;
  RealtimeChannel? _canal;

  Future<List<AsesorMonitorResumen>> cargarResumenHoy() async {
    final hoy = DateTime.now().toIso8601String().split('T').first;
    try {
      final rows = await _client
          .from('carteradiaria')
          .select(
            'asesorid, nombrecliente, estadovisita, latitud, longitud, updatedat',
          )
          .eq('fechaasignacion', hoy);

      final map = <String, _Acum>{};
      for (final r in rows as List) {
        final row = Map<String, dynamic>.from(r as Map);
        final aid = row['asesorid']?.toString() ?? '';
        if (aid.isEmpty) continue;
        map.putIfAbsent(aid, () => _Acum(aid));
        final a = map[aid]!;
        a.total++;
        if (row['estadovisita'] == 'visitado') a.visitados++;
        final lat = (row['latitud'] as num?)?.toDouble();
        final lng = (row['longitud'] as num?)?.toDouble();
        final upd = DateTime.tryParse(row['updatedat']?.toString() ?? '');
        if (lat != null && lng != null) {
          if (a.ultimaActualizacion == null ||
              (upd != null && upd.isAfter(a.ultimaActualizacion!))) {
            a.latitud = lat;
            a.longitud = lng;
            a.ultimaActualizacion = upd;
            a.nombreMuestra = row['nombrecliente']?.toString();
          }
        }
      }

      return map.values
          .map(
            (a) => AsesorMonitorResumen(
              asesorid: a.asesorid,
              nombreAsesor: a.nombreMuestra ?? 'Asesor ${a.asesorid}',
              total: a.total,
              visitados: a.visitados,
              latitud: a.latitud,
              longitud: a.longitud,
              ultimaActualizacion: a.ultimaActualizacion,
            ),
          )
          .toList()
        ..sort((x, y) => y.progreso.compareTo(x.progreso));
    } catch (_) {
      return [];
    }
  }

  void suscribirCambios(void Function() onCambio) {
    _canal?.unsubscribe();
    _canal = _client
        .channel('monitor_carteradiaria')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'carteradiaria',
          callback: (_) => onCambio(),
        )
        .subscribe();
  }

  void cancelarSuscripcion() {
    _canal?.unsubscribe();
    _canal = null;
  }
}

class _Acum {
  final String asesorid;
  int total = 0;
  int visitados = 0;
  double? latitud;
  double? longitud;
  DateTime? ultimaActualizacion;
  String? nombreMuestra;

  _Acum(this.asesorid);
}
