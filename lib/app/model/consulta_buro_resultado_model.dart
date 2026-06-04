class EntidadDeudaModel {
  final String entidad;
  final double deuda;

  EntidadDeudaModel({required this.entidad, required this.deuda});

  factory EntidadDeudaModel.fromJson(Map<String, dynamic> json) {
    return EntidadDeudaModel(
      entidad: json['entidad']?.toString() ?? '',
      deuda: ConsultaBuroResultadoModel._toDouble(json['deuda']),
    );
  }
}

class ConsultaBuroResultadoModel {
  final String? consultaId;
  final String documento;
  final String? nombres;
  final String clasificacionSbs;
  final List<EntidadDeudaModel> entidadesConDeuda;
  final double deudaTotal;
  final double mayorDeuda;
  final int diasMoraHistorica;
  final bool enListaNegra;
  final String? listaNegraMotivo;
  final bool reutilizada;
  final String? fechaConsulta;
  final String? mensajeReutilizacion;

  ConsultaBuroResultadoModel({
    this.consultaId,
    required this.documento,
    this.nombres,
    required this.clasificacionSbs,
    required this.entidadesConDeuda,
    required this.deudaTotal,
    required this.mayorDeuda,
    required this.diasMoraHistorica,
    required this.enListaNegra,
    this.listaNegraMotivo,
    this.reutilizada = false,
    this.fechaConsulta,
    this.mensajeReutilizacion,
  });

  factory ConsultaBuroResultadoModel.fromJson(Map<String, dynamic> json) {
    final entidadesRaw = json['entidades_con_deuda'];
    final entidades = <EntidadDeudaModel>[];
    if (entidadesRaw is List) {
      for (final e in entidadesRaw) {
        if (e is Map) {
          entidades.add(EntidadDeudaModel.fromJson(
            Map<String, dynamic>.from(e),
          ));
        }
      }
    }

    return ConsultaBuroResultadoModel(
      consultaId: json['consulta_id']?.toString() ?? json['id']?.toString(),
      documento: json['documento']?.toString() ?? '',
      nombres: json['nombres']?.toString(),
      clasificacionSbs: json['clasificacion_sbs']?.toString() ?? 'Normal',
      entidadesConDeuda: entidades,
      deudaTotal: _toDouble(json['deuda_total']),
      mayorDeuda: _toDouble(json['mayor_deuda']),
      diasMoraHistorica: _toInt(json['dias_mora_historica']),
      enListaNegra: json['enlistanegra'] == true,
      listaNegraMotivo: json['lista_negra_motivo']?.toString(),
      reutilizada: json['reutilizada'] == true,
      fechaConsulta: json['createdat']?.toString() ??
          json['fecha_consentimiento']?.toString(),
      mensajeReutilizacion: json['mensaje_reutilizacion']?.toString(),
    );
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}

/// Consulta previa disponible para reutilizar (30 días).
class ConsultaBuroRecienteModel {
  final String id;
  final String documento;
  final String? nombres;
  final String clasificacionSbs;
  final double deudaTotal;
  final bool enListaNegra;
  final String createdat;

  ConsultaBuroRecienteModel({
    required this.id,
    required this.documento,
    this.nombres,
    required this.clasificacionSbs,
    required this.deudaTotal,
    required this.enListaNegra,
    required this.createdat,
  });

  factory ConsultaBuroRecienteModel.fromJson(Map<String, dynamic> json) {
    return ConsultaBuroRecienteModel(
      id: json['id']?.toString() ?? '',
      documento: json['documento']?.toString() ?? '',
      nombres: json['nombres']?.toString(),
      clasificacionSbs: json['clasificacion_sbs']?.toString() ?? '',
      deudaTotal: ConsultaBuroResultadoModel._toDouble(json['deuda_total']),
      enListaNegra: json['enlistanegra'] == true,
      createdat: json['createdat']?.toString() ?? '',
    );
  }
}
