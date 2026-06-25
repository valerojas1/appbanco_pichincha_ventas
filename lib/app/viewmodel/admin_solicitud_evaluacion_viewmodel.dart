import 'dart:convert';

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/formato_fecha.dart';

import '../core/amortizacion_francesa.dart';

import '../model/cronograma_cuota_model.dart';

import '../model/documento_slot_model.dart';

import '../model/estado_solicitud.dart';

import '../model/perfil_oficial.dart';

import '../model/solicitud_nota_interna_model.dart';

import '../model/solicitud_resumen_model.dart';

import '../services/admin_solicitud_evaluacion_service.dart';

import '../services/solicitud_documento_service.dart';

import '../services/solicitud_estado_service.dart';

import '../services/solicitud_nota_interna_service.dart';

import '../services/solicitud_pdf_service.dart';

import 'solicitud_detalle_viewmodel.dart';



class AdminSolicitudEvaluacionViewModel extends ChangeNotifier {

  final AdminSolicitudEvaluacionService _evaluacionService =

      AdminSolicitudEvaluacionService();

  final SolicitudEstadoService _estadoService = SolicitudEstadoService();

  final SolicitudDocumentoService _docService = SolicitudDocumentoService();

  final SolicitudNotaInternaService _notasService = SolicitudNotaInternaService();

  final SolicitudPdfService _pdfService = SolicitudPdfService();



  SolicitudDetalleModel? _detalle;

  Map<String, DocumentoSlotModel> _slots = {};

  List<SolicitudNotaInternaModel> _notas = [];

  List<EtapaLineaTiempo> _lineaTiempo = [];

  List<CronogramaCuotaModel> _cronograma = [];

  bool _cargando = false;

  bool _procesando = false;

  bool _generandoPdf = false;

  bool _docsCompletos = false;

  String? _error;

  String _asesorId = '';

  String _autorNombre = '';



  SolicitudDetalleModel? get detalle => _detalle;

  Map<String, DocumentoSlotModel> get slots => _slots;

  List<SolicitudNotaInternaModel> get notas => _notas;

  List<EtapaLineaTiempo> get lineaTiempo => _lineaTiempo;

  List<CronogramaCuotaModel> get cronograma => _cronograma;

  bool get cargando => _cargando;

  bool get procesando => _procesando;

  bool get generandoPdf => _generandoPdf;

  bool get docsCompletos => _docsCompletos;

  String? get error => _error;



  bool get puedeIniciarEvaluacion =>

      _detalle?.estado == EstadoSolicitud.recibidoComite && _docsCompletos;



  bool get puedeRecibirEnComite =>

      _detalle?.estado == EstadoSolicitud.enviada && _docsCompletos;



  bool get puedeAprobar => _detalle?.estado == EstadoSolicitud.enEvaluacion;



  bool get puedeCondicionar => _detalle?.estado == EstadoSolicitud.enEvaluacion;



  bool get puedeRechazar {

    final e = _detalle?.estado;

    return e == EstadoSolicitud.enviada ||

        e == EstadoSolicitud.recibidoComite ||

        e == EstadoSolicitud.enEvaluacion ||

        e == EstadoSolicitud.enComite;

  }



  bool get puedeDesembolsar {

    final e = _detalle?.estado;

    return e == EstadoSolicitud.aprobada || e == EstadoSolicitud.condicionada;

  }



  bool get muestraCronograma =>

      _detalle?.estado == EstadoSolicitud.aprobada ||

      _detalle?.estado == EstadoSolicitud.condicionada ||

      _detalle?.estado == EstadoSolicitud.desembolsada;



  bool get esTerminal =>

      _detalle?.estado == EstadoSolicitud.desembolsada ||

      _detalle?.estado == EstadoSolicitud.rechazada;



  Uint8List? get firmaBytes {

    final b64 = _detalle?.firmaDigital;

    if (b64 == null || b64.isEmpty) return null;

    try {

      final raw = b64.contains(',') ? b64.split(',').last : b64;

      return base64Decode(raw);

    } catch (_) {

      return null;

    }

  }



  Future<void> cargar({

    required String solicitudId,

    required String asesorId,

    required String autorNombre,

  }) async {

    _asesorId = asesorId;

    _autorNombre = autorNombre;

    _cargando = true;

    _error = null;

    notifyListeners();



    _detalle = await _estadoService.obtenerDetalle(solicitudId);

    _slots = await _docService.cargarSlots(solicitudId);

    _docsCompletos =

        await _evaluacionService.documentacionObligatoriaCompleta(solicitudId);

    _notas = await _notasService.listar(solicitudId);

    if (_detalle != null) {

      _lineaTiempo = _construirLineaTiempo(_detalle!);

      _cronograma = _calcularCronograma(_detalle!);

    }



    _cargando = false;

    notifyListeners();

  }



  List<CronogramaCuotaModel> _calcularCronograma(SolicitudDetalleModel d) {

    if (!muestraCronograma && d.estado != EstadoSolicitud.desembolsada) {

      return [];

    }

    final filas = AmortizacionFrancesa.generarCronograma(

      monto: d.montoEfectivo,

      teaPorcentaje: d.tea,

      plazoMeses: d.plazoMeses,

    );

    final fechaRef = d.fechaDesembolso ?? d.fechaAprobacion;

    final diaPago = d.diaPago;

    return filas

        .map((f) => CronogramaCuotaModel(

              numero: f.numero,

              cuota: d.cuotaMensual ?? f.cuota,

              capital: f.capital,

              interes: f.interes,

              saldo: f.saldo,

              fechaVencimiento: fechaRef != null && diaPago != null

                  ? FormatoFecha.vencimientoCuota(

                      fechaReferencia: fechaRef,

                      diaPago: diaPago,

                      numeroCuota: f.numero,

                    )

                  : null,

            ))

        .toList();

  }



  List<EtapaLineaTiempo> _construirLineaTiempo(SolicitudDetalleModel d) {

    final e = d.estado;



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



    final orden = [

      ('Recibido en comité', d.fechaRecibidoComite ?? d.fechaEnvio, 0),

      ('En evaluación', d.fechaEvaluacion, 1),

      (e == EstadoSolicitud.condicionada ? 'Condicionada' : 'Aprobada',

          d.fechaAprobacion, 2),

      ('Desembolsada', d.fechaDesembolso, 3),

    ];



    var nivelActual = -1;

    switch (e) {

      case EstadoSolicitud.recibidoComite:

        nivelActual = 0;

        break;

      case EstadoSolicitud.enEvaluacion:

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

      return EtapaLineaTiempo(

        titulo: item.$1,

        completada: idx <= nivelActual,

        futura: idx > nivelActual,

        fecha: item.$2 as DateTime?,

      );

    }).toList();

  }



  Future<String?> iniciarEvaluacion() => _ejecutarAccion(

        () => _evaluacionService.iniciarEvaluacion(

          solicitudId: _detalle!.id,

          nombreAnalista: _autorNombre,

        ),

      );



  Future<String?> recibirEnComite() => _ejecutarAccion(

        () => _evaluacionService.recibirEnComite(

          solicitudId: _detalle!.id,

          nombreAnalista: _autorNombre,

        ),

      );



  Future<String?> aprobar({

    required double montoAprobado,

    required double cuotaMensual,

    int? diaPago,

  }) =>

      _ejecutarAccion(

        () => _evaluacionService.aprobar(

          solicitudId: _detalle!.id,

          montoAprobado: montoAprobado,

          cuotaMensual: cuotaMensual,

          diaPago: diaPago,

          nombreAnalista: _autorNombre,

        ),

      );



  Future<String?> condicionar({

    required String codigoCondicion,

    required double montoAprobado,

    required String motivo,

  }) =>

      _ejecutarAccion(

        () => _evaluacionService.condicionar(

          solicitudId: _detalle!.id,

          codigoCondicion: codigoCondicion,

          montoAprobado: montoAprobado,

          motivo: motivo,

          nombreAnalista: _autorNombre,

        ),

      );



  Future<String?> rechazar(String motivo) => _ejecutarAccion(

        () => _evaluacionService.rechazar(

          solicitudId: _detalle!.id,

          motivo: motivo,

        ),

      );



  Future<String?> registrarDesembolso({

    required DateTime fechaDesembolso,

    int? diaPago,

  }) =>

      _ejecutarAccion(

        () => _evaluacionService.registrarDesembolso(

          solicitudId: _detalle!.id,

          fechaDesembolso: fechaDesembolso,

          diaPago: diaPago,

        ),

      );



  Future<String?> _ejecutarAccion(

    Future<ResultadoCambioEstado> Function() accion,

  ) async {

    if (_detalle == null) return 'Sin solicitud cargada';

    _procesando = true;

    _error = null;

    notifyListeners();



    final resultado = await accion();

    if (!resultado.ok) {

      _procesando = false;

      _error = resultado.error;

      notifyListeners();

      return resultado.error;

    }



    _detalle = resultado.detalle;

    _docsCompletos =

        await _evaluacionService.documentacionObligatoriaCompleta(_detalle!.id);

    if (_detalle != null) {

      _lineaTiempo = _construirLineaTiempo(_detalle!);

      _cronograma = _calcularCronograma(_detalle!);

    }



    _procesando = false;

    notifyListeners();

    return null;

  }



  Future<bool> agregarNota(String contenido) async {

    if (_detalle == null) return false;

    final ok = await _notasService.agregar(

      solicitudId: _detalle!.id,

      asesorId: _asesorId,

      autorNombre: _autorNombre,

      perfil: PerfilOficial.administrador,

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

