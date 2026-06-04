import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/preevaluacion_resultado_model.dart';

class PreEvaluacionService {
  final SupabaseClient _client = Supabase.instance.client;
  final Connectivity _connectivity = Connectivity();
  static const String _offlineKey = 'preevaluaciones_offline';

  Future<bool> get hayConexion async {
    final r = await _connectivity.checkConnectivity();
    return r.isNotEmpty && !r.contains(ConnectivityResult.none);
  }

  Future<PreEvaluacionResultadoModel?> evaluar({
    required String asesorid,
    required String dni,
    required String nombres,
    required String tiponegocio,
    required double ingresos,
    required String destino,
    required double monto,
  }) async {
    final payload = {
      'asesorid': asesorid,
      'dni': dni,
      'nombres': nombres,
      'tiponegocio': tiponegocio,
      'ingresos': ingresos,
      'destino': destino,
      'monto': monto,
    };

    if (!await hayConexion) {
      await _encolar(payload);
      return null;
    }

    try {
      final res = await _client.functions.invoke('pre-evaluar', body: payload);
      final data = res.data;
      if (data is Map) {
        return PreEvaluacionResultadoModel.fromJson(
          Map<String, dynamic>.from(data),
        );
      }
    } catch (_) {
      await _encolar(payload);
    }
    return null;
  }

  Future<void> _encolar(Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    final lista = await _listarCola();
    payload['encolado_at'] = DateTime.now().toIso8601String();
    lista.add(payload);
    await prefs.setString(_offlineKey, jsonEncode(lista));
  }

  Future<List<Map<String, dynamic>>> _listarCola() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_offlineKey);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(raw));
  }

  Future<int> getOfflineCount() async {
    final lista = await _listarCola();
    return lista.length;
  }

  Future<int> sincronizarPendientes() async {
    if (!await hayConexion) return 0;
    final lista = await _listarCola();
    var ok = 0;
    final pendientes = <Map<String, dynamic>>[];

    for (final item in lista) {
      try {
        final res = await _client.functions.invoke('pre-evaluar', body: item);
        if (res.data is Map) ok++;
        else pendientes.add(item);
      } catch (_) {
        pendientes.add(item);
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_offlineKey, jsonEncode(pendientes));
    return ok;
  }

  Future<void> clearOfflineCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_offlineKey);
  }

  /// Evalúa localmente cuando está en cola (misma lógica que la Edge Function).
  PreEvaluacionResultadoModel evaluarLocal({
    required double ingresos,
    required double monto,
    required String destino,
  }) {
    final ing = ingresos < 1 ? 1 : ingresos;
    final ratio = monto / ing;
    final dest = destino.toLowerCase();

    if (monto < 500 || monto > 50000) {
      return PreEvaluacionResultadoModel(
        resultado: 'NO PROCEDE',
        mensaje: 'Monto fuera del rango permitido (S/ 500 – S/ 50,000).',
        ratioDeudaIngreso: ratio,
        desdeCola: true,
      );
    }
    if (ratio > 4 || ingresos < 800) {
      return PreEvaluacionResultadoModel(
        resultado: 'NO PROCEDE',
        mensaje: 'Capacidad de pago insuficiente (evaluación en cola offline).',
        ratioDeudaIngreso: ratio,
        desdeCola: true,
      );
    }
    if (ratio > 2.5 || (dest.contains('invers') && ratio > 2)) {
      return PreEvaluacionResultadoModel(
        resultado: 'REVISAR',
        mensaje: 'Requiere revisión (pendiente sincronizar con servidor).',
        ratioDeudaIngreso: ratio,
        desdeCola: true,
      );
    }
    if (ratio > 1.8) {
      return PreEvaluacionResultadoModel(
        resultado: 'REVISAR',
        mensaje: 'Evaluación preliminar favorable con observaciones (offline).',
        ratioDeudaIngreso: ratio,
        desdeCola: true,
      );
    }
    return PreEvaluacionResultadoModel(
      resultado: 'APTO',
      mensaje: 'Pre-evaluación preliminar favorable (se confirmará al reconectar).',
      ratioDeudaIngreso: ratio,
      desdeCola: true,
    );
  }
}
