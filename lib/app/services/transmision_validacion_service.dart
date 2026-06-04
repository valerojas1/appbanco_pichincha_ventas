import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/solicitud_credito_data.dart';
import '../model/tipo_documento_config.dart';
import '../services/consulta_buro_service.dart';

/// Validación previa completa antes de transmitir.
class TransmisionValidacionService {
  final SupabaseClient _client = Supabase.instance.client;
  final ConsultaBuroService _buro = ConsultaBuroService();

  Future<List<String>> validarCompleta(String solicitudId) async {
    final errores = <String>[];

    Map<String, dynamic>? row;
    try {
      row = await _client
          .from('solicitudescredito')
          .select()
          .eq('id', solicitudId)
          .maybeSingle();
    } catch (_) {
      errores.add('No se pudo cargar la solicitud');
      return errores;
    }

    if (row == null) {
      errores.add('Solicitud no encontrada');
      return errores;
    }

    final data = _mapRowToData(row);
    errores.addAll(_validarFormulario(data));

    if (data.firmaBase64 == null || data.firmaBase64!.isEmpty) {
      errores.add('Falta la firma digital del solicitante');
    }
    if (!data.declaracionJurada) {
      errores.add('Falta aceptar la declaración jurada');
    }

    final doc = data.dni.replaceAll(RegExp(r'\D'), '');
    if (await _buro.documentoEnListaNegraActiva(doc)) {
      errores.add('Cliente en lista negra — no puede transmitirse');
    } else {
      final buro = await _buro.ultimaConsultaValida(doc);
      if (buro == null) {
        errores.add(
          'Sin consulta de buró válida (últimos 30 días). Realice la consulta primero.',
        );
      }
    }

    errores.addAll(await _validarDocumentos(solicitudId));

    return errores;
  }

  List<String> _validarFormulario(SolicitudCreditoData d) {
    final errores = <String>[];
    void req(bool ok, String msg) {
      if (!ok) errores.add(msg);
    }

    req(d.nombres.trim().isNotEmpty, 'Falta nombres del solicitante');
    req(d.apellidos.trim().isNotEmpty, 'Falta apellidos del solicitante');
    req(RegExp(r'^\d{8}$').hasMatch(d.dni.trim()), 'DNI inválido (8 dígitos)');
    req(d.fechaNacimiento != null, 'Falta fecha de nacimiento');
    final edad = d.edad;
    req(edad != null && edad >= 18 && edad <= 75, 'Edad fuera de rango (18-75)');
    req(d.telefono.trim().length >= 9, 'Teléfono inválido');
    req(d.tipoNegocio.trim().isNotEmpty, 'Falta tipo de negocio');
    req(d.nombreNegocio.trim().isNotEmpty, 'Falta nombre del negocio');
    req(d.direccionNegocio.trim().isNotEmpty, 'Falta dirección del negocio');
    req(d.antiguedadMeses >= 6, 'Antigüedad mínima 6 meses');
    req(d.ingresosEstimados > 0, 'Ingresos estimados inválidos');
    req(d.destinoCredito.trim().isNotEmpty, 'Falta destino del crédito');
    req(d.monto >= 500 && d.monto <= 150000, 'Monto fuera de rango permitido');
    req(
      [3, 6, 12, 18, 24, 36, 48, 60].contains(d.plazoMeses),
      'Plazo no válido',
    );

    if (d.requiereConyuge) {
      req(d.conyugeNombres.trim().isNotEmpty, 'Faltan datos del cónyuge');
      req(
        RegExp(r'^\d{8}$').hasMatch(d.conyugeDni.trim()),
        'DNI del cónyuge inválido',
      );
    }
    if (d.incluirGarante) {
      req(d.garanteNombres.trim().isNotEmpty, 'Faltan datos del garante');
      req(
        RegExp(r'^\d{8}$').hasMatch(d.garanteDni.trim()),
        'DNI del garante inválido',
      );
    }

    return errores;
  }

  Future<List<String>> _validarDocumentos(String solicitudId) async {
    final errores = <String>[];
    try {
      final rows = await _client
          .from('solicitudesdocumentos')
          .select('tipodocumento, estado, obligatorio')
          .eq('solicitudid', solicitudId);

      final listos = <String>{};
      for (final raw in rows as List) {
        final row = Map<String, dynamic>.from(raw as Map);
        if (row['estado']?.toString() == 'listo') {
          listos.add(row['tipodocumento']?.toString() ?? '');
        }
      }

      for (final t in TipoDocumentoConfig.catalogo) {
        if (t.obligatorio && !listos.contains(t.id)) {
          errores.add('Documento obligatorio pendiente: ${t.titulo}');
        }
      }
    } catch (_) {
      errores.add('No se pudieron verificar los documentos');
    }
    return errores;
  }

  SolicitudCreditoData _mapRowToData(Map<String, dynamic> row) {
    return SolicitudCreditoData(
      asesorid: row['asesorid']?.toString() ?? '',
      nombres: row['nombres']?.toString() ?? '',
      apellidos: row['apellidos']?.toString() ?? '',
      dni: row['dni']?.toString() ?? '',
      fechaNacimiento: row['fechanacimiento'] != null
          ? DateTime.tryParse(row['fechanacimiento'].toString())
          : null,
      estadoCivil: row['estadocivil']?.toString() ?? 'soltero',
      gradoInstruccion: row['gradoinstruccion']?.toString() ?? 'secundaria',
      telefono: row['telefono']?.toString() ?? '',
      email: row['email']?.toString() ?? '',
      conyugeNombres: row['conyugenombres']?.toString() ?? '',
      conyugeDni: row['conyugedni']?.toString() ?? '',
      garanteNombres: row['garantenombres']?.toString() ?? '',
      garanteDni: row['garantedni']?.toString() ?? '',
      incluirGarante: row['garantedni'] != null &&
          row['garantedni'].toString().isNotEmpty,
      tipoNegocio: row['tiponegocio']?.toString() ?? '',
      nombreNegocio: row['nombrenegocio']?.toString() ?? '',
      direccionNegocio: row['direccionnegocio']?.toString() ?? '',
      antiguedadMeses: row['antiguedadmeses'] is int
          ? row['antiguedadmeses'] as int
          : int.tryParse(row['antiguedadmeses']?.toString() ?? '') ?? 0,
      ingresosEstimados: _toDouble(row['ingresosestimados']),
      gastosEstimados: _toDouble(row['gastosestimados']),
      destinoCredito: row['destinocredito']?.toString() ?? '',
      codigoCiiu: row['codigociiu']?.toString() ?? '4711',
      monto: _toDouble(row['monto'], 5000),
      plazoMeses: row['plazomeses'] is int
          ? row['plazomeses'] as int
          : int.tryParse(row['plazomeses']?.toString() ?? '') ?? 12,
      moneda: row['moneda']?.toString() ?? 'PEN',
      tipoCuota: row['tipocuota']?.toString() ?? 'fija',
      tipoGarantia: row['tipogarantia']?.toString() ?? 'personal',
      tea: _toDouble(row['tea'], 28),
      firmaBase64: row['firmadigital']?.toString(),
      declaracionJurada: row['declaracionjurada'] == true,
    );
  }

  double _toDouble(dynamic v, [double def = 0]) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? def;
  }
}
