import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/oficial_model.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<OficialModel?> login(String codigo, String password) async {
    try {
      final response = await _client
          .from('usuariosmock')
          .select()
          .eq('codigoempleado', codigo)
          .eq('clave', password)
          .eq('rol', 'asesor')
          .maybeSingle();
      if (response == null) return null;
      return OficialModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }
}
