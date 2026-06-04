class CampanaActivaModel {
  final String id;
  final String asesorid;
  final String tipocampana;
  final String nombrecliente;
  final double montooferta;
  final String fechavencimiento;
  final bool activa;
  final String? clienteid;

  CampanaActivaModel({
    required this.id,
    required this.asesorid,
    required this.tipocampana,
    required this.nombrecliente,
    required this.montooferta,
    required this.fechavencimiento,
    required this.activa,
    this.clienteid,
  });

  int get diasRestantes {
    final venc = DateTime.tryParse(fechavencimiento);
    if (venc == null) return 0;
    final hoy = DateTime.now();
    final diff = venc.difference(DateTime(hoy.year, hoy.month, hoy.day)).inDays;
    return diff < 0 ? 0 : diff;
  }

  factory CampanaActivaModel.fromJson(Map<String, dynamic> json) {
    return CampanaActivaModel(
      id: json['id']?.toString() ?? '',
      asesorid: json['asesorid']?.toString() ?? '',
      tipocampana: json['tipocampana']?.toString() ?? '',
      nombrecliente: json['nombrecliente']?.toString() ?? '',
      montooferta: _toDouble(json['montooferta']),
      fechavencimiento: json['fechavencimiento']?.toString() ?? '',
      activa: json['activa'] == true,
      clienteid: json['clienteid']?.toString(),
    );
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }
}
