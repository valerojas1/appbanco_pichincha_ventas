import 'estado_solicitud.dart';

class SolicitudResumenModel {
  final String id;
  final String nombres;
  final String apellidos;
  final double monto;
  final EstadoSolicitud? estado;
  final String? numeroExpediente;
  final String? analistaAsignado;
  final DateTime? fechaEnvio;
  final DateTime? createdAt;

  SolicitudResumenModel({
    required this.id,
    required this.nombres,
    required this.apellidos,
    required this.monto,
    this.estado,
    this.numeroExpediente,
    this.analistaAsignado,
    this.fechaEnvio,
    this.createdAt,
  });

  String get nombreCliente => '$nombres $apellidos'.trim();

  int get diasDesdeEnvio {
    final ref = fechaEnvio ?? createdAt;
    if (ref == null) return 0;
    return DateTime.now().difference(ref).inDays;
  }

  factory SolicitudResumenModel.fromJson(Map<String, dynamic> json) {
    return SolicitudResumenModel(
      id: json['id']?.toString() ?? '',
      nombres: json['nombres']?.toString() ?? '',
      apellidos: json['apellidos']?.toString() ?? '',
      monto: _toDouble(json['monto']),
      estado: EstadoSolicitud.fromDb(json['estado']?.toString()),
      numeroExpediente: json['numeroexpediente']?.toString(),
      analistaAsignado: json['analistaasignado']?.toString(),
      fechaEnvio: _parseDate(json['fechaeenvio']),
      createdAt: _parseDate(json['createdat']),
    );
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}

class SolicitudDetalleModel extends SolicitudResumenModel {
  final String dni;
  final String? telefono;
  final int plazoMeses;
  final double? cuotaMensual;
  final String? motivoRechazo;
  final DateTime? fechaComite;
  final DateTime? fechaAprobacion;
  final DateTime? fechaDesembolso;
  final String? firmaDigital;
  final bool declaracionJurada;

  SolicitudDetalleModel({
    required super.id,
    required super.nombres,
    required super.apellidos,
    required super.monto,
    super.estado,
    super.numeroExpediente,
    super.analistaAsignado,
    super.fechaEnvio,
    super.createdAt,
    required this.dni,
    this.telefono,
    this.plazoMeses = 12,
    this.cuotaMensual,
    this.motivoRechazo,
    this.fechaComite,
    this.fechaAprobacion,
    this.fechaDesembolso,
    this.firmaDigital,
    this.declaracionJurada = false,
  });

  factory SolicitudDetalleModel.fromJson(Map<String, dynamic> json) {
    return SolicitudDetalleModel(
      id: json['id']?.toString() ?? '',
      nombres: json['nombres']?.toString() ?? '',
      apellidos: json['apellidos']?.toString() ?? '',
      monto: SolicitudResumenModel._toDouble(json['monto']),
      estado: EstadoSolicitud.fromDb(json['estado']?.toString()),
      numeroExpediente: json['numeroexpediente']?.toString(),
      analistaAsignado: json['analistaasignado']?.toString(),
      fechaEnvio: SolicitudResumenModel._parseDate(json['fechaeenvio']),
      createdAt: SolicitudResumenModel._parseDate(json['createdat']),
      dni: json['dni']?.toString() ?? '',
      telefono: json['telefono']?.toString(),
      plazoMeses: json['plazomeses'] is int
          ? json['plazomeses'] as int
          : int.tryParse(json['plazomeses']?.toString() ?? '') ?? 12,
      cuotaMensual: SolicitudResumenModel._toDouble(json['cuotamensual']),
      motivoRechazo: json['motivorechazo']?.toString(),
      fechaComite: SolicitudResumenModel._parseDate(json['fechacomite']),
      fechaAprobacion: SolicitudResumenModel._parseDate(json['fechaaprobacion']),
      fechaDesembolso: SolicitudResumenModel._parseDate(json['fechadesembolso']),
      firmaDigital: json['firmadigital']?.toString(),
      declaracionJurada: json['declaracionjurada'] == true,
    );
  }
}
