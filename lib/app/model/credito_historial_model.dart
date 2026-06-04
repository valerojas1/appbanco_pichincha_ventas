class CreditoHistorialModel {
  final String id;
  final String clienteid;
  final String numerocredito;
  final double monto;
  final int plazomeses;
  final double tea;
  final String estado;
  final String? fechadesembolso;
  final double saldopendiente;

  CreditoHistorialModel({
    required this.id,
    required this.clienteid,
    required this.numerocredito,
    required this.monto,
    required this.plazomeses,
    required this.tea,
    required this.estado,
    this.fechadesembolso,
    required this.saldopendiente,
  });

  factory CreditoHistorialModel.fromJson(Map<String, dynamic> json) {
    return CreditoHistorialModel(
      id: json['id']?.toString() ?? '',
      clienteid: json['clienteid']?.toString() ?? '',
      numerocredito: json['numerocredito']?.toString() ?? '',
      monto: _toDouble(json['monto']),
      plazomeses: _toInt(json['plazomeses']),
      tea: _toDouble(json['tea']),
      estado: json['estado']?.toString() ?? '',
      fechadesembolso: json['fechadesembolso']?.toString(),
      saldopendiente: _toDouble(json['saldopendiente']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'clienteid': clienteid,
        'numerocredito': numerocredito,
        'monto': monto,
        'plazomeses': plazomeses,
        'tea': tea,
        'estado': estado,
        'fechadesembolso': fechadesembolso,
        'saldopendiente': saldopendiente,
      };

  static int _toInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }
}
