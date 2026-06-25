import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/solicitud_credito_data.dart';
import 'solicitudes_borrador_db.dart';

class SolicitudCreditoService {
  final SupabaseClient _client = Supabase.instance.client;
  final SolicitudesBorradorDb _borradorDb = SolicitudesBorradorDb();
  final Connectivity _connectivity = Connectivity();

  Future<bool> get hayConexion async {
    final r = await _connectivity.checkConnectivity();
    return r.isNotEmpty && !r.contains(ConnectivityResult.none);
  }

  /// Inserta nueva solicitud o actualiza una retomada del cliente.
  Future<String?> enviarSolicitud(SolicitudCreditoData data) async {
    if (!await hayConexion) {
      await _borradorDb.encolarEnvio(data);
      return null;
    }
    try {
      final payload = data.toSupabasePayload();
      payload['estado'] = 'documentos_pendientes';
      payload['updatedat'] = DateTime.now().toIso8601String();

      if (data.solicitudIdServidor != null) {
        await _client
            .from('solicitudescredito')
            .update(payload)
            .eq('id', data.solicitudIdServidor!)
            .eq('asesorid', data.asesorid);
        if (data.borradorIdLocal != null) {
          await _borradorDb.eliminarBorrador(data.borradorIdLocal!);
        }
        return data.solicitudIdServidor;
      }

      final row = await _client
          .from('solicitudescredito')
          .insert(payload)
          .select('id')
          .single();
      if (data.borradorIdLocal != null) {
        await _borradorDb.eliminarBorrador(data.borradorIdLocal!);
      }
      return row['id']?.toString();
    } catch (e) {
      try {
        await _borradorDb.encolarEnvio(data);
      } catch (_) {}
      throw Exception(
        'No se pudo guardar la solicitud en el servidor. '
        'Verifique conexión y datos. Detalle: $e',
      );
    }
  }

  Future<int> sincronizarColaPendiente() async {
    if (!await hayConexion) return 0;
    final cola = await _borradorDb.listarColaEnvio();
    var enviadas = 0;
    for (final row in cola) {
      final id = row['id'] as String;
      try {
        final data = SolicitudCreditoData.fromJson(
          Map<String, dynamic>.from(
            jsonDecode(row['payload'] as String) as Map,
          ),
        );
        await _client.from('solicitudescredito').insert(data.toSupabasePayload());
        await _borradorDb.eliminarDeCola(id);
        enviadas++;
      } catch (_) {}
    }
    return enviadas;
  }

  Future<int> contarPendientesEnvio() => _borradorDb.contarColaEnvio();

  Future<void> limpiarColaEnvio() => _borradorDb.limpiarColaEnvio();

  SolicitudesBorradorDb get borradorDb => _borradorDb;
}
