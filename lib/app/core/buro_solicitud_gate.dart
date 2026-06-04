import 'package:flutter/material.dart';
import '../model/consulta_buro_resultado_model.dart';
import '../services/consulta_buro_service.dart';
import '../view/home/consulta_buro_screen.dart';
import '../view/home/widgets/lista_negra_bloqueo_dialog.dart';

/// Valida buró / lista negra antes de abrir la solicitud de crédito.
class BuroSolicitudGate {
  static final ConsultaBuroService _service = ConsultaBuroService();

  static String _normalizarDni(String dni) =>
      dni.replaceAll(RegExp(r'\D'), '');

  /// Retorna `true` si puede continuar hacia la solicitud.
  static Future<bool> validarAntesDeSolicitud(
    BuildContext context, {
    required String dni,
    String? nombres,
  }) async {
    final doc = _normalizarDni(dni);
    if (doc.length != 8) {
      _snack(context, 'Ingrese un DNI válido de 8 dígitos');
      return false;
    }

    if (await _service.documentoEnListaNegraActiva(doc)) {
      await mostrarListaNegraBloqueo(context, documento: doc);
      return false;
    }

    final ultima = await _service.ultimaConsultaValida(doc);
    if (ultima != null) return true;

    final irConsulta = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2744),
        title: const Text(
          'Consulta de buró requerida',
          style: TextStyle(color: Color(0xFFFFD100)),
        ),
        content: Text(
          'No hay una consulta de buró válida (últimos 30 días) para el DNI $doc. '
          'Debe registrar el consentimiento y consultar antes de la solicitud.',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('IR A CONSULTA BURÓ'),
          ),
        ],
      ),
    );

    if (irConsulta == true && context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConsultaBuroScreen(
            args: ConsultaBuroArgs(documento: doc, nombres: nombres),
          ),
        ),
      );
      if (!context.mounted) return false;
      final trasConsulta = await _service.ultimaConsultaValida(doc);
      return trasConsulta != null;
    }
    return false;
  }

  /// Tras ejecutar consulta: bloquea si lista negra.
  static Future<void> manejarResultadoConsulta(
    BuildContext context,
    ConsultaBuroResultadoModel resultado,
  ) async {
    if (resultado.enListaNegra) {
      await mostrarListaNegraBloqueo(
        context,
        documento: resultado.documento,
        motivo: resultado.listaNegraMotivo,
      );
    }
  }

  static void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}
