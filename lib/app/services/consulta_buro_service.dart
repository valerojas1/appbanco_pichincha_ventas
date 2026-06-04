import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/consulta_buro_resultado_model.dart';

class ConsultaBuroService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<ConsultaBuroRecienteModel?> buscarConsultaReciente(
    String documento,
  ) async {
    try {
      final res = await _client.functions.invoke(
        'consulta-buro',
        body: {
          'documento': documento,
          'solo_verificar_reciente': true,
        },
      );
      final data = res.data;
      if (data is! Map) return null;
      final map = Map<String, dynamic>.from(data);
      if (map['tiene_reciente'] != true) return null;
      final rec = map['consulta_reciente'];
      if (rec is Map) {
        return ConsultaBuroRecienteModel.fromJson(
          Map<String, dynamic>.from(rec),
        );
      }
    } catch (_) {}
    return null;
  }

  Future<ConsultaBuroResultadoModel?> ejecutarConsulta({
    required String documento,
    required String asesorid,
    required String firmaConsentimientoBase64,
    String? nombres,
    String? reutilizarConsultaId,
  }) async {
    try {
      final res = await _client.functions.invoke(
        'consulta-buro',
        body: {
          'documento': documento,
          'asesorid': asesorid,
          'firma_consentimiento': firmaConsentimientoBase64,
          'nombres': nombres,
          if (reutilizarConsultaId != null)
            'reutilizar_consulta_id': reutilizarConsultaId,
        },
      );
      final data = res.data;
      if (data is Map) {
        return ConsultaBuroResultadoModel.fromJson(
          Map<String, dynamic>.from(data),
        );
      }
    } catch (_) {}
    return null;
  }

  Future<bool> documentoEnListaNegraActiva(String documento) async {
    try {
      final row = await _client
          .from('listasnegras')
          .select('documento')
          .eq('documento', documento)
          .eq('activo', true)
          .maybeSingle();
      return row != null;
    } catch (_) {
      return false;
    }
  }

  Future<ConsultaBuroResultadoModel?> ultimaConsultaValida(
    String documento,
  ) async {
    try {
      final hace30 = DateTime.now().subtract(const Duration(days: 30));
      final row = await _client
          .from('consultasburo')
          .select()
          .eq('documento', documento)
          .eq('enlistanegra', false)
          .gte('createdat', hace30.toIso8601String())
          .order('createdat', ascending: false)
          .limit(1)
          .maybeSingle();
      if (row == null) return null;
      return ConsultaBuroResultadoModel.fromJson(
        Map<String, dynamic>.from(row),
      );
    } catch (_) {
      return null;
    }
  }
}
