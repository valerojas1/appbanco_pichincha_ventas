class CarteraVencidaModel {
  final String id;
  final String asesorid;
  final String dni;
  final String nombreCliente;
  final String? telefono;
  final String numeroCredito;
  final double saldoVencido;
  final int diasMora;
  final DateTime? fechaVencimiento;
  final DateTime? ultimaAccionAt;

  CarteraVencidaModel({
    required this.id,
    required this.asesorid,
    required this.dni,
    required this.nombreCliente,
    this.telefono,
    required this.numeroCredito,
    required this.saldoVencido,
    required this.diasMora,
    this.fechaVencimiento,
    this.ultimaAccionAt,
  });

  factory CarteraVencidaModel.fromJson(Map<String, dynamic> json) {
    return CarteraVencidaModel(
      id: json['id']?.toString() ?? '',
      asesorid: json['asesorid']?.toString() ?? '',
      dni: json['dni']?.toString() ?? '',
      nombreCliente: json['nombrecliente']?.toString() ?? '',
      telefono: json['telefono']?.toString(),
      numeroCredito: json['numerocredito']?.toString() ?? '',
      saldoVencido: _toDouble(json['saldovencido']),
      diasMora: (json['diasmora'] as num?)?.toInt() ?? 0,
      fechaVencimiento: _parseDate(json['fechavencimiento']),
      ultimaAccionAt: _parseDateTime(json['ultimaaccionat']),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  static DateTime? _parseDateTime(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}
