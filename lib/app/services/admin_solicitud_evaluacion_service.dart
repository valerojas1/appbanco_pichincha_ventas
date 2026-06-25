import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/amortizacion_francesa.dart';

import '../model/estado_solicitud.dart';

import '../model/solicitud_resumen_model.dart';

import '../model/tipo_documento_config.dart';

import 'solicitud_documento_service.dart';

import 'solicitud_estado_service.dart';



class ResultadoCambioEstado {

  final bool ok;

  final String? error;

  final SolicitudDetalleModel? detalle;



  const ResultadoCambioEstado({

    required this.ok,

    this.error,

    this.detalle,

  });

}



/// Cambios de estado del ciclo de comité (portal administrador).

class AdminSolicitudEvaluacionService {

  final SupabaseClient _client = Supabase.instance.client;

  final SolicitudEstadoService _estadoService = SolicitudEstadoService();

  final SolicitudDocumentoService _docService = SolicitudDocumentoService();



  static const _transicionesPermitidas = {

    EstadoSolicitud.enviada: [

      EstadoSolicitud.recibidoComite,

      EstadoSolicitud.enComite,

      EstadoSolicitud.rechazada,

    ],

    EstadoSolicitud.recibidoComite: [

      EstadoSolicitud.enEvaluacion,

      EstadoSolicitud.rechazada,

    ],

    EstadoSolicitud.enEvaluacion: [

      EstadoSolicitud.aprobada,

      EstadoSolicitud.condicionada,

      EstadoSolicitud.rechazada,

    ],

    EstadoSolicitud.enComite: [

      EstadoSolicitud.aprobada,

      EstadoSolicitud.condicionada,

      EstadoSolicitud.rechazada,

    ],

    EstadoSolicitud.aprobada: [EstadoSolicitud.desembolsada],

    EstadoSolicitud.condicionada: [EstadoSolicitud.desembolsada],

  };



  Future<bool> documentacionObligatoriaCompleta(String solicitudId) async {

    final slots = await _docService.cargarSlots(solicitudId);

    for (final tipo in TipoDocumentoConfig.catalogo.where((t) => t.obligatorio)) {

      if (!(slots[tipo.id]?.estaListo ?? false)) return false;

    }

    return true;

  }



  Future<ResultadoCambioEstado> iniciarEvaluacion({

    required String solicitudId,

    String? nombreAnalista,

  }) async {

    final detalle = await _estadoService.obtenerDetalle(solicitudId);

    if (detalle == null) {

      return const ResultadoCambioEstado(ok: false, error: 'Solicitud no encontrada');

    }

    if (!_puedeTransicionar(detalle.estado, EstadoSolicitud.enEvaluacion)) {

      return const ResultadoCambioEstado(

        ok: false,

        error: 'Solo se puede evaluar una solicitud recibida en comité',

      );

    }



    final ahora = DateTime.now().toIso8601String();

    final payload = <String, dynamic>{

      'estado': EstadoSolicitud.enEvaluacion.dbValue,

      'fechaevaluacion': ahora,

      'updatedat': ahora,

    };

    if (nombreAnalista != null && nombreAnalista.isNotEmpty) {

      payload['analistaasignado'] = nombreAnalista;

    }

    return _aplicarCambio(solicitudId, payload);

  }



  /// Compatibilidad con flujo anterior (enviada → en_comite).

  Future<ResultadoCambioEstado> recibirEnComite({

    required String solicitudId,

    String? nombreAnalista,

  }) async {

    final detalle = await _estadoService.obtenerDetalle(solicitudId);

    if (detalle == null) {

      return const ResultadoCambioEstado(ok: false, error: 'Solicitud no encontrada');

    }

    if (detalle.estado == EstadoSolicitud.recibidoComite) {

      return iniciarEvaluacion(

        solicitudId: solicitudId,

        nombreAnalista: nombreAnalista,

      );

    }

    if (!_puedeTransicionar(detalle.estado, EstadoSolicitud.enComite)) {

      return const ResultadoCambioEstado(

        ok: false,

        error: 'Solo se puede recibir una solicitud enviada',

      );

    }

    if (!await documentacionObligatoriaCompleta(solicitudId)) {

      return const ResultadoCambioEstado(

        ok: false,

        error: 'Faltan documentos obligatorios por revisar',

      );

    }



    final ahora = DateTime.now().toIso8601String();

    final payload = <String, dynamic>{

      'estado': EstadoSolicitud.enComite.dbValue,

      'fechacomite': ahora,

      'updatedat': ahora,

    };

    if (nombreAnalista != null && nombreAnalista.isNotEmpty) {

      payload['analistaasignado'] = nombreAnalista;

    }

    return _aplicarCambio(solicitudId, payload);

  }



  Future<ResultadoCambioEstado> aprobar({

    required String solicitudId,

    required double montoAprobado,

    required double cuotaMensual,

    int? diaPago,

    String? nombreAnalista,

  }) async {

    final detalle = await _estadoService.obtenerDetalle(solicitudId);

    if (detalle == null) {

      return const ResultadoCambioEstado(ok: false, error: 'Solicitud no encontrada');

    }

    if (!_puedeTransicionar(detalle.estado, EstadoSolicitud.aprobada)) {

      return const ResultadoCambioEstado(

        ok: false,

        error: 'Solo se puede aprobar una solicitud en evaluación',

      );

    }

    if (montoAprobado <= 0) {

      return const ResultadoCambioEstado(

        ok: false,

        error: 'El monto aprobado debe ser mayor a 0',

      );

    }

    if (cuotaMensual <= 0) {

      return const ResultadoCambioEstado(

        ok: false,

        error: 'La cuota mensual debe ser mayor a 0',

      );

    }

    if (diaPago != null && (diaPago < 1 || diaPago > 28)) {

      return const ResultadoCambioEstado(

        ok: false,

        error: 'El día de pago debe estar entre 1 y 28',

      );

    }



    final ahora = DateTime.now().toIso8601String();

    final payload = <String, dynamic>{

      'estado': EstadoSolicitud.aprobada.dbValue,

      'montodaprobado': montoAprobado,

      'cuotamensual': cuotaMensual,

      'fechaaprobacion': ahora,

      'updatedat': ahora,

    };

    if (diaPago != null) payload['diapago'] = diaPago;

    if (nombreAnalista != null && nombreAnalista.isNotEmpty) {

      payload['analistaasignado'] = nombreAnalista;

    }

    return _aplicarCambio(solicitudId, payload);

  }



  Future<ResultadoCambioEstado> condicionar({

    required String solicitudId,

    required String codigoCondicion,

    required double montoAprobado,

    required String motivo,

    String? nombreAnalista,

  }) async {

    final detalle = await _estadoService.obtenerDetalle(solicitudId);

    if (detalle == null) {

      return const ResultadoCambioEstado(ok: false, error: 'Solicitud no encontrada');

    }

    if (!_puedeTransicionar(detalle.estado, EstadoSolicitud.condicionada)) {

      return const ResultadoCambioEstado(

        ok: false,

        error: 'Solo se puede condicionar una solicitud en evaluación',

      );

    }

    if (!['25', '26', '27'].contains(codigoCondicion)) {

      return const ResultadoCambioEstado(

        ok: false,

        error: 'Código de condición inválido (use 25, 26 o 27)',

      );

    }

    if (montoAprobado <= 0 || montoAprobado >= detalle.monto) {

      return ResultadoCambioEstado(

        ok: false,

        error:

            'El monto aprobado debe ser mayor a 0 y menor al solicitado (S/ ${detalle.monto.toStringAsFixed(0)})',

      );

    }

    if (motivo.trim().length < 5) {

      return const ResultadoCambioEstado(

        ok: false,

        error: 'Indique un motivo de condición (mínimo 5 caracteres)',

      );

    }



    final cuota = AmortizacionFrancesa.calcularCuota(

      monto: montoAprobado,

      teaPorcentaje: detalle.tea,

      plazoMeses: detalle.plazoMeses,

    );



    final ahora = DateTime.now().toIso8601String();

    final payload = <String, dynamic>{

      'estado': EstadoSolicitud.condicionada.dbValue,

      'montodaprobado': montoAprobado,

      'codigocondicion': codigoCondicion,

      'motivocondicion': motivo.trim(),

      'cuotamensual': cuota,

      'fechaaprobacion': ahora,

      'updatedat': ahora,

    };

    if (nombreAnalista != null && nombreAnalista.isNotEmpty) {

      payload['analistaasignado'] = nombreAnalista;

    }

    return _aplicarCambio(solicitudId, payload);

  }



  Future<ResultadoCambioEstado> rechazar({

    required String solicitudId,

    required String motivo,

  }) async {

    final detalle = await _estadoService.obtenerDetalle(solicitudId);

    if (detalle == null) {

      return const ResultadoCambioEstado(ok: false, error: 'Solicitud no encontrada');

    }

    final estado = detalle.estado;

    final rechazables = {

      EstadoSolicitud.enviada,

      EstadoSolicitud.recibidoComite,

      EstadoSolicitud.enEvaluacion,

      EstadoSolicitud.enComite,

    };

    if (!rechazables.contains(estado)) {

      return const ResultadoCambioEstado(

        ok: false,

        error: 'No se puede rechazar en el estado actual',

      );

    }

    if (motivo.trim().length < 5) {

      return const ResultadoCambioEstado(

        ok: false,

        error: 'Indique un motivo de rechazo (mínimo 5 caracteres)',

      );

    }



    final ahora = DateTime.now().toIso8601String();

    return _aplicarCambio(solicitudId, {

      'estado': EstadoSolicitud.rechazada.dbValue,

      'motivorechazo': motivo.trim(),

      'updatedat': ahora,

    });

  }



  Future<ResultadoCambioEstado> registrarDesembolso({

    required String solicitudId,

    required DateTime fechaDesembolso,

    int? diaPago,

  }) async {

    final detalle = await _estadoService.obtenerDetalle(solicitudId);

    if (detalle == null) {

      return const ResultadoCambioEstado(ok: false, error: 'Solicitud no encontrada');

    }

    if (!_puedeTransicionar(detalle.estado, EstadoSolicitud.desembolsada)) {

      return const ResultadoCambioEstado(

        ok: false,

        error: 'Solo se puede desembolsar una solicitud aprobada o condicionada',

      );

    }

    if (diaPago != null && (diaPago < 1 || diaPago > 28)) {

      return const ResultadoCambioEstado(

        ok: false,

        error: 'El día de pago debe estar entre 1 y 28',

      );

    }



    final fecha = DateTime(

      fechaDesembolso.year,

      fechaDesembolso.month,

      fechaDesembolso.day,

    );

    final payload = <String, dynamic>{

      'estado': EstadoSolicitud.desembolsada.dbValue,

      'fechadesembolso': fecha.toIso8601String().split('T').first,

      'updatedat': DateTime.now().toIso8601String(),

    };

    if (diaPago != null) payload['diapago'] = diaPago;

    return _aplicarCambio(solicitudId, payload);

  }



  bool _puedeTransicionar(EstadoSolicitud? actual, EstadoSolicitud destino) {

    if (actual == null) return false;

    return _transicionesPermitidas[actual]?.contains(destino) ?? false;

  }



  Future<ResultadoCambioEstado> _aplicarCambio(

    String solicitudId,

    Map<String, dynamic> payload,

  ) async {

    try {

      await _client.from('solicitudescredito').update(payload).eq('id', solicitudId);

      final detalle = await _estadoService.obtenerDetalle(solicitudId);

      return ResultadoCambioEstado(ok: true, detalle: detalle);

    } catch (e) {

      return ResultadoCambioEstado(

        ok: false,

        error: 'No se pudo actualizar el estado: $e',

      );

    }

  }

}

