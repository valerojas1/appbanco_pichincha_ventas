import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/campana_activa_model.dart';

class CampanaActivaService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<CampanaActivaModel>> listarVigentes(String asesorid) async {
    try {
      final hoy = DateTime.now().toIso8601String().split('T').first;
      final rows = await _client
          .from('campanasactivas')
          .select()
          .eq('asesorid', asesorid)
          .eq('activa', true)
          .gte('fechavencimiento', hoy)
          .order('fechavencimiento', ascending: true);
      return (rows as List)
          .map((e) => CampanaActivaModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
