import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/cliente_financiero_model.dart';

class ClienteCreditoService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<ClienteFinancieroModel>> getClientesActivos() async {
    return _fetchPorEstado('activo');
  }

  Future<List<ClienteFinancieroModel>> getProspectosCredito() async {
    return _fetchPorEstado('prospecto');
  }

  Future<List<ClienteFinancieroModel>> _fetchPorEstado(String estado) async {
    try {
      final response = await _client
          .from('vwclientesfinancieros')
          .select()
          .eq('estadocliente', estado)
          .order('nombres');
      return (response as List)
          .map((e) => ClienteFinancieroModel.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
