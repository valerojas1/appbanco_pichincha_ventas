import 'package:flutter/material.dart';
import '../model/estado_solicitud.dart';
import '../model/perfil_oficial.dart';
import '../model/solicitud_nota_interna_model.dart';
import '../model/solicitud_resumen_model.dart';
import '../services/solicitud_estado_service.dart';
import '../services/solicitud_nota_interna_service.dart';
import '../services/solicitud_pdf_service.dart';

class EtapaLineaTiempo {
  final String titulo;
  final bool completada;
  final bool futura;
  final DateTime? fecha;

  EtapaLineaTiempo({
    required this.titulo,
    required this.completada,
    required this.futura,
    this.fecha,
  });
}

class SolicitudDetalleViewModel extends ChangeNotifier {
  final SolicitudEstadoService _estadoService = SolicitudEstadoService();
  final SolicitudNotaInternaService _notasService = SolicitudNotaInternaService();
  final SolicitudPdfService _pdfService = SolicitudPdfService();

  SolicitudDetalleModel? _detalle;
  List<SolicitudNotaInternaModel> _notas = [];
  List<EtapaLineaTiempo> _lineaTiempo = [];
  bool _cargando = false;
  bool _generandoPdf = false;
  String? _error;
  PerfilOficial _perfil = PerfilOficial.operador;
  String _asesorId = '';
  String _autorNombre = '';

  SolicitudDetalleModel? get detalle => _detalle;
  List<SolicitudNotaInternaModel> get notas => _notas;
  List<EtapaLineaTiempo> get lineaTiempo => _lineaTiempo;
  bool get cargando => _cargando;
  bool get generandoPdf => _generandoPdf;
  String? get error => _error;
  bool get puedeAgregarNota => _notasService.puedeAgregarNota(_perfil);

  Future<void> cargar({
    required String solicitudId,
    required String asesorId,
    required String autorNombre,
    required PerfilOficial perfil,
  }) async {
    _asesorId = asesorId;
    _autorNombre = autorNombre;
    _perfil = perfil;
    _cargando = true;
    _error = null;
    notifyListeners();

    _detalle = await _estadoService.obtenerDetalle(solicitudId);
    if (_notasService.puedeVerNotas(perfil)) {
      _notas = await _notasService.listar(solicitudId);
    }
    if (_detalle != null) {
      _lineaTiempo = _construirLineaTiempo(_detalle!);
    }

    _cargando = false;
    notifyListeners();
  }

  List<EtapaLineaTiempo> _construirLineaTiempo(SolicitudDetalleModel d) {
    final e = d.estado;
    final orden = [
      ('Recibido en comité', d.fechaRecibidoComite ?? d.fechaEnvio, 0),
      ('En evaluación', d.fechaEvaluacion, 1),
      (e == EstadoSolicitud.condicionada ? 'Condicionada' : 'Aprobada',
          d.fechaAprobacion, 2),
      ('Desembolsada', d.fechaDesembolso, 3),
    ];

    int nivelActual = -1;
    if (e == EstadoSolicitud.rechazada) {
      return [
        EtapaLineaTiempo(
          titulo: 'Recibido en comité',
          completada: d.fechaRecibidoComite != null || d.fechaEnvio != null,
          futura: false,
          fecha: d.fechaRecibidoComite ?? d.fechaEnvio,
        ),
        EtapaLineaTiempo(
          titulo: 'Rechazada',
          completada: true,
          futura: false,
          fecha: null,
        ),
      ];
    }

    switch (e) {
      case EstadoSolicitud.recibidoComite:
      case EstadoSolicitud.enviada:
        nivelActual = 0;
        break;
      case EstadoSolicitud.enEvaluacion:
      case EstadoSolicitud.enComite:
        nivelActual = 1;
        break;
      case EstadoSolicitud.aprobada:
      case EstadoSolicitud.condicionada:
        nivelActual = 2;
        break;
      case EstadoSolicitud.desembolsada:
        nivelActual = 3;
        break;
      default:
        nivelActual = d.fechaEnvio != null ? 0 : -1;
    }

    return orden.map((item) {
      final idx = item.$3;
      final completada = idx <= nivelActual;
      final futura = idx > nivelActual;
      return EtapaLineaTiempo(
        titulo: item.$1,
        completada: completada,
        futura: futura,
        fecha: item.$2 as DateTime?,
      );
    }).toList();
  }

  Future<bool> agregarNota(String contenido) async {
    if (_detalle == null) return false;
    final ok = await _notasService.agregar(
      solicitudId: _detalle!.id,
      asesorId: _asesorId,
      autorNombre: _autorNombre,
      perfil: _perfil,
      contenido: contenido,
    );
    if (ok) {
      _notas = await _notasService.listar(_detalle!.id);
      notifyListeners();
    }
    return ok;
  }

  Future<void> compartirPdf() async {
    if (_detalle == null) return;
    _generandoPdf = true;
    notifyListeners();
    try {
      final bytes = await _pdfService.generarPdf(_detalle!);
      final nombre =
          'solicitud_${_detalle!.numeroExpediente ?? _detalle!.id}.pdf';
      await _pdfService.compartirPdf(bytes, nombre);
    } catch (e) {
      _error = 'No se pudo generar el PDF: $e';
    }
    _generandoPdf = false;
    notifyListeners();
  }
}
