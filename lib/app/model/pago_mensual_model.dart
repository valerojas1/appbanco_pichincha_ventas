class PagoMensualModel {
  final String id;
  final String clienteid;
  final String periodo;
  final String estado;
  final double montopagado;
  final int diasmora;

  PagoMensualModel({
    required this.id,
    required this.clienteid,
    required this.periodo,
    required this.estado,
    required this.montopagado,
    required this.diasmora,
  });

  bool get esPuntual => estado == 'puntual';
  bool get esMora => estado == 'mora';
  bool get esSinCuota => estado == 'sin_cuota';

  factory PagoMensualModel.fromJson(Map<String, dynamic> json) {
    return PagoMensualModel(
      id: json['id']?.toString() ?? '',
      clienteid: json['clienteid']?.toString() ?? '',
      periodo: json['periodo']?.toString() ?? '',
      estado: json['estado']?.toString() ?? 'sin_cuota',
      montopagado: _toDouble(json['montopagado']),
      diasmora: _toInt(json['diasmora']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'clienteid': clienteid,
        'periodo': periodo,
        'estado': estado,
        'montopagado': montopagado,
        'diasmora': diasmora,
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
