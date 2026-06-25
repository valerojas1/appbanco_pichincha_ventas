import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/tipo_documento_config.dart';
import '../model/transmision_paso.dart';
import 'transmision_estado_local_service.dart';
import 'transmision_validacion_service.dart';

class TransmisionElectronicaService {
  final SupabaseClient _client = Supabase.instance.client;
  final TransmisionValidacionService _validacion = TransmisionValidacionService();
  final TransmisionEstadoLocalService _local = TransmisionEstadoLocalService();

  Future<List<String>> ejecutarPaso({
    required String solicitudId,
    required TransmisionPaso paso,
  }) async {
    switch (paso) {
      case TransmisionPaso.validando:
        return _validacion.validarCompleta(solicitudId);
      case TransmisionPaso.subiendoDocs:
        return _verificarDocumentosParalelo(solicitudId);
      case TransmisionPaso.registrando:
        return _registrarSolicitud(solicitudId);
      case TransmisionPaso.asignandoExpediente:
        return _asignarExpediente(solicitudId);
      case TransmisionPaso.enviado:
        await _local.guardarPasoCompletado(
          solicitudId: solicitudId,
          paso: TransmisionPaso.enviado,
        );
        return [];
    }
  }

  Future<int> pasoParaReanudar(String solicitudId) async {
    final ultimo = await _local.ultimoPasoCompletado(solicitudId);
    if (ultimo < 0) return 0;
    return (ultimo + 1).clamp(0, TransmisionPaso.enviado.indice);
  }

  Future<void> marcarPasoOk({
    required String solicitudId,
    required TransmisionPaso paso,
    String? numeroExpediente,
  }) async {
    await _local.guardarPasoCompletado(
      solicitudId: solicitudId,
      paso: paso,
      numeroExpediente: numeroExpediente,
    );
  }

  Future<void> limpiarProgresoLocal(String solicitudId) async {
    await _local.limpiar(solicitudId);
  }

  Future<String?> obtenerNumeroExpediente(String solicitudId) async {
    try {
      final row = await _client
          .from('solicitudescredito')
          .select('numeroexpediente')
          .eq('id', solicitudId)
          .maybeSingle();
      return row?['numeroexpediente']?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<List<String>> _verificarDocumentosParalelo(String solicitudId) async {
    final errores = <String>[];
    try {
      final futures = TipoDocumentoConfig.catalogo
          .where((t) => t.obligatorio)
          .map((t) async {
            final row = await _client
                .from('solicitudesdocumentos')
                .select('estado, storagepath')
                .eq('solicitudid', solicitudId)
                .eq('tipodocumento', t.id)
                .maybeSingle();
            if (row == null ||
                row['estado']?.toString() != 'listo' ||
                (row['storagepath']?.toString() ?? '').isEmpty) {
              return 'Documento no sincronizado: ${t.titulo}';
            }
            return null;
          });

      final resultados = await Future.wait(futures);
      for (final r in resultados) {
        if (r != null) errores.add(r);
      }
    } catch (_) {
      errores.add('Error al verificar documentos en paralelo');
    }
    return errores;
  }

  Future<List<String>> _registrarSolicitud(String solicitudId) async {
    try {
      final ahora = DateTime.now().toIso8601String();
      await _client.from('solicitudescredito').update({
        'estado': 'recibido_comite',
        'fechaeenvio': ahora,
        'fecharecibidocomite': ahora,
        'updatedat': ahora,
      }).eq('id', solicitudId);
      return [];
    } catch (e) {
      return ['Error al registrar: $e'];
    }
  }

  Future<List<String>> _asignarExpediente(String solicitudId) async {
    try {
      final expediente = _generarNumeroExpediente(solicitudId);
      const analistas = [
        'Ana Torres',
        'Luis Mendoza',
        'Carmen Vela',
        'Roberto Díaz',
      ];
      final analista = analistas[solicitudId.hashCode.abs() % analistas.length];

      await _client.from('solicitudescredito').update({
        'numeroexpediente': expediente,
        'analistaasignado': analista,
        'updatedat': DateTime.now().toIso8601String(),
      }).eq('id', solicitudId);

      await _local.guardarPasoCompletado(
        solicitudId: solicitudId,
        paso: TransmisionPaso.asignandoExpediente,
        numeroExpediente: expediente,
      );

      return [];
    } catch (e) {
      return ['Error al asignar expediente: $e'];
    }
  }

  String _generarNumeroExpediente(String solicitudId) {
    final year = DateTime.now().year;
    final seq = solicitudId.replaceAll(RegExp(r'\D'), '');
    final suffix = seq.length >= 6
        ? seq.substring(seq.length - 6)
        : seq.padLeft(6, '0');
    return 'BP-$year-$suffix';
  }
}
