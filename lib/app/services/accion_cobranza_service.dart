import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/accion_cobranza_enums.dart';

class AccionCobranzaService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<bool> registrar({
    required String carteravencidaid,
    required String asesorid,
    required TipoAccionCobranza tipo,
    required ResultadoAccionCobranza resultado,
    required String observaciones,
    required double? latitud,
    required double? longitud,
    required DateTime registradoAt,
    double? montoCompromiso,
    DateTime? fechaCompromiso,
    double? montoPago,
  }) async {
    final payload = <String, dynamic>{
      'carteravencidaid': carteravencidaid,
      'asesorid': asesorid,
      'tipo': tipo.db,
      'resultado': resultado.db,
      'observaciones': observaciones.length > 500
          ? observaciones.substring(0, 500)
          : observaciones,
      'latitud': latitud,
      'longitud': longitud,
      'registradoat': registradoAt.toIso8601String(),
    };

    if (montoCompromiso != null) {
      payload['montocompromiso'] = montoCompromiso;
    }
    if (fechaCompromiso != null) {
      payload['fechacompromiso'] =
          fechaCompromiso.toIso8601String().split('T').first;
    }
    if (montoPago != null) {
      payload['montopago'] = montoPago;
    }

    try {
      await _client.from('accionescobranza').insert(payload);
      return true;
    } catch (_) {
      return false;
    }
  }
}
