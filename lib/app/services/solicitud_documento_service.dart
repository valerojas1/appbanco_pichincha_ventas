import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/documento_slot_model.dart';
import '../model/tipo_documento_config.dart';

class SolicitudDocumentoService {
  static const String bucket = 'documentos-solicitudes';
  final SupabaseClient _client = Supabase.instance.client;

  String storagePath(String solicitudId, String tipo) =>
      '$solicitudId/$tipo.jpg';

  String urlPublica(String path) =>
      _client.storage.from(bucket).getPublicUrl(path);

  Future<Map<String, DocumentoSlotModel>> cargarSlots(
    String solicitudId,
  ) async {
    final map = {
      for (final t in TipoDocumentoConfig.catalogo)
        t.id: DocumentoSlotModel(config: t),
    };

    try {
      final rows = await _client
          .from('solicitudesdocumentos')
          .select()
          .eq('solicitudid', solicitudId);

      for (final raw in rows as List) {
        final row = Map<String, dynamic>.from(raw as Map);
        final tipo = row['tipodocumento']?.toString() ?? '';
        if (!map.containsKey(tipo)) continue;
        final path = row['storagepath']?.toString() ?? '';
        map[tipo] = DocumentoSlotModel(
          config: map[tipo]!.config,
          registroId: row['id']?.toString(),
          storagePath: path,
          urlPublica: path.isNotEmpty ? urlPublica(path) : null,
          puntajeNitidez: _toNullableDouble(row['puntajenitidez']),
          tamanoKb: row['tamanokb'] as int?,
        );
      }
    } catch (_) {}

    return map;
  }

  Future<DocumentoSlotModel> subirDocumento({
    required String solicitudId,
    required TipoDocumentoConfig tipo,
    required Uint8List bytesJpeg,
    required double puntajeNitidez,
  }) async {
    final comprimido = bytesJpeg;
    final path = storagePath(solicitudId, tipo.id);

    await _client.storage.from(bucket).uploadBinary(
          path,
          comprimido,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );

    final payload = {
      'solicitudid': solicitudId,
      'tipodocumento': tipo.id,
      'obligatorio': tipo.obligatorio,
      'storagepath': path,
      'estado': 'listo',
      'puntajenitidez': puntajeNitidez,
      'tamanokb': (comprimido.length / 1024).round(),
      'updatedat': DateTime.now().toIso8601String(),
    };

    final existente = await _client
        .from('solicitudesdocumentos')
        .select('id')
        .eq('solicitudid', solicitudId)
        .eq('tipodocumento', tipo.id)
        .maybeSingle();

    String registroId;
    if (existente != null) {
      registroId = existente['id'].toString();
      await _client.from('solicitudesdocumentos').update(payload).eq('id', registroId);
    } else {
      final ins = await _client
          .from('solicitudesdocumentos')
          .insert(payload)
          .select('id')
          .single();
      registroId = ins['id'].toString();
    }

    return DocumentoSlotModel(
      config: tipo,
      registroId: registroId,
      storagePath: path,
      urlPublica: urlPublica(path),
      puntajeNitidez: puntajeNitidez,
      tamanoKb: (comprimido.length / 1024).round(),
    );
  }

  Future<void> eliminarDocumento({
    required String solicitudId,
    required DocumentoSlotModel slot,
  }) async {
    if (slot.storagePath != null && slot.storagePath!.isNotEmpty) {
      try {
        await _client.storage.from(bucket).remove([slot.storagePath!]);
      } catch (_) {}
    }
    if (slot.registroId != null) {
      await _client
          .from('solicitudesdocumentos')
          .delete()
          .eq('id', slot.registroId!);
    } else if (slot.config.id.isNotEmpty) {
      await _client
          .from('solicitudesdocumentos')
          .delete()
          .eq('solicitudid', solicitudId)
          .eq('tipodocumento', slot.config.id);
    }
  }

  Future<void> finalizarSolicitud(String solicitudId) async {
    await marcarListaParaTransmitir(solicitudId);
  }

  /// Marca la solicitud lista para transmisión electrónica (Bloque 8).
  Future<void> marcarListaParaTransmitir(String solicitudId) async {
    await _client.from('solicitudescredito').update({
      'estado': 'completa',
      'updatedat': DateTime.now().toIso8601String(),
    }).eq('id', solicitudId);
  }

  Future<List<Map<String, dynamic>>> listarSolicitudesPendientesDocs(
    String asesorid,
  ) async {
    try {
      final rows = await _client
          .from('solicitudescredito')
          .select('id, nombres, apellidos, monto, createdat, estado')
          .eq('asesorid', asesorid)
          .inFilter('estado', ['documentos_pendientes', 'enviada'])
          .order('createdat', ascending: false)
          .limit(30);
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (_) {
      return [];
    }
  }

  static double? _toNullableDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
