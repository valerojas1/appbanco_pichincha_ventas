import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/network_service.dart';
import '../services/app_local_database.dart';
import '../services/ficha_service.dart';
import '../services/preevaluacion_service.dart';
import '../services/solicitud_credito_service.dart';

/// Cola pendientesync: envío en lote al reconectar.
class PendingSyncRepository {
  final AppLocalDatabase _local = AppLocalDatabase.instance;
  final NetworkService _red = NetworkService.instance;
  final SupabaseClient _client = Supabase.instance.client;

  Future<int> contarPendientes() async {
    final visitas = await _local.contarVisitasPendientes();
    final fichas = await FichaService().getOfflineCount();
    final pre = await PreEvaluacionService().getOfflineCount();
    final sol = await SolicitudCreditoService().contarPendientesEnvio();
    return visitas + fichas + pre + sol;
  }

  Future<int> sincronizarTodo() async {
    if (!_red.hayConexion) return 0;

    var total = 0;
    total += await _sincronizarVisitas();
    total += await FichaService().sincronizarFichas();
    total += await PreEvaluacionService().sincronizarPendientes();
    total += await SolicitudCreditoService().sincronizarColaPendiente();
    return total;
  }

  Future<int> _sincronizarVisitas() async {
    final pendientes = await _local.listarVisitasPendientes();
    var ok = 0;

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
        ok++;
      } catch (e) {
        debugPrint('Sync visita $id: $e');
      }
    }
    return ok;
  }
}
