class OfertaPreaprobadaModel {
  final String id;
  final String fichaid;
  final String clienteidFicha;
  final double montopreaprobado;
  final int plazomeses;
  final double tea;
  final double scoreaprobacion;
  final String? fechavencimiento;

  OfertaPreaprobadaModel({
    required this.id,
    required this.fichaid,
    required this.clienteidFicha,
    required this.montopreaprobado,
    required this.plazomeses,
    required this.tea,
    required this.scoreaprobacion,
    this.fechavencimiento,
  });

  factory OfertaPreaprobadaModel.fromJson(Map<String, dynamic> json) {
    return OfertaPreaprobadaModel(
      id: json['id']?.toString() ?? '',
      fichaid: json['fichaid']?.toString() ?? '',
      clienteidFicha: json['clienteid_ficha']?.toString() ?? '',
      montopreaprobado: _toDouble(json['montopreaprobado']),
      plazomeses: _toInt(json['plazomeses']),
      tea: _toDouble(json['tea']),
      scoreaprobacion: _toDouble(json['scoreaprobacion']),
      fechavencimiento: json['fechavencimiento']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fichaid': fichaid,
        'clienteid_ficha': clienteidFicha,
        'montopreaprobado': montopreaprobado,
        'plazomeses': plazomeses,
        'tea': tea,
        'scoreaprobacion': scoreaprobacion,
        'fechavencimiento': fechavencimiento,
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
