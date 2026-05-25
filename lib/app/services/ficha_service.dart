import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/ficha_campo_model.dart';

class FichaService {
  final SupabaseClient _client = Supabase.instance.client;
  static const String _offlineKey = 'fichas_offline';

  Future<FichaCampoModel?> crearFicha(Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('fichascampo')
          .insert(data)
          .select()
          .single();
      return FichaCampoModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<void> guardarOffline(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final fichas = await _getOfflineFichas();
    fichas.add(data);
    await prefs.setString(_offlineKey, jsonEncode(fichas));
  }

  Future<List<Map<String, dynamic>>> _getOfflineFichas() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_offlineKey);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(raw));
  }

  Future<int> sincronizarFichas() async {
    final fichas = await _getOfflineFichas();
    int sincronizadas = 0;

    for (final data in fichas) {
      try {
        await _client.from('fichascampo').insert(data);
        data['estadoficha'] = 'sincronizada';
        sincronizadas++;
      } catch (_) {}
    }

    if (sincronizadas > 0) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_offlineKey, jsonEncode(fichas));
    }

    return sincronizadas;
  }

  Future<int> getOfflineCount() async {
    final fichas = await _getOfflineFichas();
    return fichas.length;
  }
}
