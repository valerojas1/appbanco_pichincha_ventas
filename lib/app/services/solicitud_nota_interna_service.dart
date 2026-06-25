import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/perfil_oficial.dart';
import '../model/solicitud_nota_interna_model.dart';

class SolicitudNotaInternaService {
  final SupabaseClient _client = Supabase.instance.client;

  bool puedeVerNotas(PerfilOficial perfil) =>
      perfil == PerfilOficial.operador ||
      perfil == PerfilOficial.superoperador ||
      perfil == PerfilOficial.supervisor ||
      perfil == PerfilOficial.administrador;

  bool puedeAgregarNota(PerfilOficial perfil) =>
      perfil == PerfilOficial.operador ||
      perfil == PerfilOficial.superoperador ||
      perfil == PerfilOficial.supervisor ||
      perfil == PerfilOficial.administrador;

  Future<List<SolicitudNotaInternaModel>> listar(String solicitudId) async {
    try {
      final rows = await _client
          .from('solicitudesnotasinternas')
          .select()
          .eq('solicitudid', solicitudId)
          .order('createdat', ascending: false);
      return (rows as List)
          .map((r) => SolicitudNotaInternaModel.fromJson(
                Map<String, dynamic>.from(r as Map),
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> agregar({
    required String solicitudId,
    required String asesorId,
    required String autorNombre,
    required PerfilOficial perfil,
    required String contenido,
  }) async {
    if (!puedeAgregarNota(perfil) || contenido.trim().isEmpty) return false;
    try {
      await _client.from('solicitudesnotasinternas').insert({
        'solicitudid': solicitudId,
        'asesorid': asesorId,
        'autornombre': autorNombre,
        'perfilautor': perfil.name,
        'contenido': contenido.trim(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
