import 'package:supabase_flutter/supabase_flutter.dart';

class ClienteDesertorService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<bool> registrar({
    required String asesorid,
    required String nombrecliente,
    String? documento,
    String? clienteid,
    required String motivo,
    required String instituciondestino,
    required int probabilidadretorno,
    String? observaciones,
  }) async {
    try {
      await _client.from('clientesdesertores').insert({
        'asesorid': asesorid,
        'nombrecliente': nombrecliente,
        'documento': documento,
        'clienteid': clienteid,
        'motivo': motivo,
        'instituciondestino': instituciondestino,
        'probabilidadretorno': probabilidadretorno,
        'observaciones': observaciones,
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
