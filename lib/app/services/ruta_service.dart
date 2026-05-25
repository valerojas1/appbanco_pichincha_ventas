import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/ruta_planificada_model.dart';

class RutaService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<RutaPlanificadaModel>> getRutaHoy(String asesorid) async {
    try {
      final today = DateTime.now().toIso8601String().split('T').first;
      final response = await _client
          .from('rutasplanificadas')
          .select()
          .eq('asesorid', asesorid)
          .gte('fecharuta', today)
          .lt('fecharuta', '${today}T23:59:59')
          .order('fecharuta');
      return (response as List).map((e) => RutaPlanificadaModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> actualizarEstadoVisita(String rutaid, String estado) async {
    try {
      await _client
          .from('rutasplanificadas')
          .update({'estadovisita': estado})
          .eq('rutaid', rutaid);
      return true;
    } catch (e) {
      return false;
    }
  }
}
