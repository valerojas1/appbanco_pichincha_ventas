import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/oficial_model.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<OficialModel?> login(String dni, String password) async {
    try {
      final user = await _client
          .from('usuariosmock')
          .select()
          .eq('dni', dni)
          .eq('passwordhash', password)
          .eq('rol', 'asesor')
          .single();

      final asesor = await _client
          .from('asesoresnegocio')
          .select()
          .eq('userid', user['id'])
          .single();

      return OficialModel.fromJson({
        ...user,
        'asesorid': asesor['id'],
        'codigoasesor': asesor['codigoasesor'],
        'zonaasignada': asesor['zonaasignada'],
        'especialidad': asesor['especialidad'],
      });
    } catch (e) {
      return null;
    }
  }
}
