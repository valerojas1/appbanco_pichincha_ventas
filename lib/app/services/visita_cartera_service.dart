import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'app_local_database.dart';

class VisitaCarteraService {
  final SupabaseClient _client = Supabase.instance.client;
  final AppLocalDatabase _local = AppLocalDatabase.instance;
  static const String _offlineKeyLegacy = 'visitas_cartera_offline';
  static const _uuid = Uuid();
  bool _migrado = false;

  Future<bool> registrarVisita({
    required String carteraid,
    required String asesorid,
    required String resultado,
    required String observacion,
    required double? latitud,
    required double? longitud,
    required DateTime registradoAt,
  }) async {
    await _migrarLegacySiAplica();

    final payload = {
      'carteraid': carteraid,
      'asesorid': asesorid,
      'resultado': resultado,
      'observacion': observacion.length > 200
          ? observacion.substring(0, 200)
          : observacion,
      'latitud': latitud,
      'longitud': longitud,
      'registradoat': registradoAt.toIso8601String(),
    };

    try {
      await _client.from('resultadosvisita').insert(payload);
      await _client.from('carteradiaria').update({
        'estadovisita': resultado,
        'updatedat': registradoAt.toIso8601String(),
      }).eq('id', carteraid);
      return true;
    } catch (_) {
      await _local.insertarVisitaPendiente(
        id: _uuid.v4(),
        payload: payload,
      );
      return false;
    }
  }

  Future<void> _migrarLegacySiAplica() async {
    if (_migrado) return;
    _migrado = true;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_offlineKeyLegacy);
    if (raw == null) return;
    try {
      final lista = List<Map<String, dynamic>>.from(jsonDecode(raw));
      for (final data in lista) {
        await _local.insertarVisitaPendiente(
          id: _uuid.v4(),
          payload: Map<String, dynamic>.from(data),
        );
      }
      await prefs.remove(_offlineKeyLegacy);
    } catch (_) {}
  }

  Future<int> sincronizarPendientes() async {
    await _migrarLegacySiAplica();
    final pendientes = await _local.listarVisitasPendientes();
    var sincronizadas = 0;

    for (final item in pendientes) {
      final data = item['payload'] as Map<String, dynamic>;
      final id = item['id'] as String;
      try {
        await _client.from('resultadosvisita').insert({
          'carteraid': data['carteraid'],
          'asesorid': data['asesorid'],
          'resultado': data['resultado'],
          'observacion': data['observacion'],
          'latitud': data['latitud'],
          'longitud': data['longitud'],
          'registradoat': data['registradoat'],
        });
        await _client.from('carteradiaria').update({
          'estadovisita': data['resultado'],
          'updatedat': data['registradoat'],
        }).eq('id', data['carteraid']);
        await _local.marcarVisitaSincronizada(id);
        sincronizadas++;
      } catch (_) {}
    }
    return sincronizadas;
  }

  Future<int> getOfflineCount() async {
    await _migrarLegacySiAplica();
    return _local.contarVisitasPendientes();
  }

  Future<void> clearOfflineCache() async {
    await _local.limpiarVisitasPendientes();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_offlineKeyLegacy);
  }
}
