import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/geocerca_zona_model.dart';

class GeocercaService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<GeocercaZonaModel>> listarActivas() async {
    try {
      final response = await _client
          .from('geocercaszonas')
          .select()
          .eq('activa', true);
      return (response as List)
          .map((e) => GeocercaZonaModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
