import 'package:flutter/material.dart';
import '../model/consulta_buro_resultado_model.dart';
import '../services/consulta_buro_service.dart';

class ConsultaBuroViewModel extends ChangeNotifier {
  final ConsultaBuroService _service = ConsultaBuroService();

  String _documento = '';
  String _nombres = '';
  ConsultaBuroRecienteModel? _consultaReciente;
  ConsultaBuroResultadoModel? _resultado;
  String? _textoInterpretativo;
  bool _cargando = false;
  bool _consentimientoAceptado = false;
  String? _firmaBase64;
  String? _error;

  String get documento => _documento;
  String get nombres => _nombres;
  ConsultaBuroRecienteModel? get consultaReciente => _consultaReciente;
  ConsultaBuroResultadoModel? get resultado => _resultado;
  String? get textoInterpretativo => _textoInterpretativo;
  bool get cargando => _cargando;
  bool get consentimientoAceptado => _consentimientoAceptado;
  String? get firmaBase64 => _firmaBase64;
  String? get error => _error;

  bool get puedeContinuarSolicitud =>
      _resultado != null && !_resultado!.enListaNegra;

  void setDocumento(String v) {
    _documento = v;
    notifyListeners();
  }

  void setNombres(String v) {
    _nombres = v;
    notifyListeners();
  }

  void setConsentimientoAceptado(bool v) {
    _consentimientoAceptado = v;
    notifyListeners();
  }

  void setFirmaBase64(String? v) {
    _firmaBase64 = v;
    notifyListeners();
  }

  Future<void> verificarConsultaReciente() async {
    final doc = _documento.replaceAll(RegExp(r'\D'), '');
    if (doc.length != 8) return;

    _cargando = true;
    _error = null;
    notifyListeners();

    _consultaReciente = await _service.buscarConsultaReciente(doc);
    _cargando = false;
    notifyListeners();
  }

  Future<bool> ejecutarConsulta({
    required String asesorid,
    bool reutilizar = false,
  }) async {
    final doc = _documento.replaceAll(RegExp(r'\D'), '');
    if (doc.length != 8) {
      _error = 'Ingrese un DNI válido de 8 dígitos';
      notifyListeners();
      return false;
    }
    if (!_consentimientoAceptado) {
      _error = 'Debe aceptar el consentimiento informado';
      notifyListeners();
      return false;
    }
    if (_firmaBase64 == null || _firmaBase64!.isEmpty) {
      _error = 'La firma del cliente es obligatoria';
      notifyListeners();
      return false;
    }

    _cargando = true;
    _error = null;
    _resultado = null;
    _textoInterpretativo = null;
    notifyListeners();

    _resultado = await _service.ejecutarConsulta(
      documento: doc,
      asesorid: asesorid,
      firmaConsentimientoBase64: _firmaBase64!,
      nombres: _nombres.trim().isEmpty ? null : _nombres.trim(),
      reutilizarConsultaId:
          reutilizar && _consultaReciente != null ? _consultaReciente!.id : null,
    );

    _cargando = false;

    if (_resultado == null) {
      _error = 'No se pudo completar la consulta de buró';
      notifyListeners();
      return false;
    }

    _textoInterpretativo = _generarTextoInterpretativo(_resultado!);
    notifyListeners();
    return true;
  }

  void aplicarResultadoExistente(ConsultaBuroResultadoModel r) {
    _resultado = r;
    _textoInterpretativo = _generarTextoInterpretativo(r);
    notifyListeners();
  }

  String _generarTextoInterpretativo(ConsultaBuroResultadoModel r) {
    final buffer = StringBuffer();
    final sbs = r.clasificacionSbs.toUpperCase();
    final nEnt = r.entidadesConDeuda.length;

    buffer.write('El cliente con DNI ${r.documento}');
    if (r.nombres != null && r.nombres!.isNotEmpty) {
      buffer.write(' (${r.nombres})');
    }
    buffer.write(' presenta una calificación SBS "$sbs". ');

    if (r.deudaTotal <= 0) {
      buffer.write(
        'No se registran deudas vigentes reportadas en las fuentes consultadas, '
        'lo que sugiere un perfil sin exposición crediticia activa al momento de la consulta. ',
      );
    } else {
      buffer.write(
        'La deuda total reportada asciende a S/ ${r.deudaTotal.toStringAsFixed(0)} '
        'distribuida en $nEnt entidad${nEnt == 1 ? '' : 'es'}. ',
      );
      if (r.mayorDeuda > 0) {
        buffer.write(
          'La mayor exposición individual es de S/ ${r.mayorDeuda.toStringAsFixed(0)}. ',
        );
      }
    }

    if (r.diasMoraHistorica > 0) {
      buffer.write(
        'Se identifica historial de mora de hasta ${r.diasMoraHistorica} días, '
        'por lo que se recomienda validar capacidad de pago y conducta de pagos recientes. ',
      );
    } else {
      buffer.write(
        'No se reportan días de mora histórica significativos en la consulta. ',
      );
    }

    switch (sbs) {
      case 'NORMAL':
        buffer.write(
          'En conjunto, el perfil es compatible con evaluación crediticia estándar, '
          'sujeto a políticas internas del banco.',
        );
        break;
      case 'CPP':
        buffer.write(
          'El perfil CPP (con problemas potenciales) sugiere cautela: '
          'conviene profundizar en causas de atraso y exigir garantías adicionales si aplica.',
        );
        break;
      case 'DEFICIENTE':
      case 'DUDOSO':
      case 'PÉRDIDA':
      case 'PERDIDA':
        buffer.write(
          'La calificación SBS refleja deterioro crediticio. '
          'Se desaconseja el otorgamiento de nuevo crédito sin excepción aprobada por comité.',
        );
        break;
      default:
        buffer.write(
          'Se recomienda revisión manual por el área de riesgos antes de continuar.',
        );
    }

    if (r.reutilizada) {
      buffer.write(
        ' Nota: este resultado fue reutilizado de una consulta previa de los últimos 30 días.',
      );
    }

    if (r.enListaNegra) {
      buffer.write(
        ' ALERTA: el cliente figura en lista negra interna. No procede la solicitud de crédito.',
      );
    }

    return buffer.toString().trim();
  }

  void reiniciar() {
    _resultado = null;
    _textoInterpretativo = null;
    _consultaReciente = null;
    _error = null;
    _consentimientoAceptado = false;
    _firmaBase64 = null;
    notifyListeners();
  }
}
