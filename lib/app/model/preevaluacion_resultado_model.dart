class PreEvaluacionResultadoModel {
  final String resultado;
  final String mensaje;
  final double? ratioDeudaIngreso;
  final bool desdeCola;

  PreEvaluacionResultadoModel({
    required this.resultado,
    required this.mensaje,
    this.ratioDeudaIngreso,
    this.desdeCola = false,
  });

  bool get esApto => resultado == 'APTO';
  bool get esRevisar => resultado == 'REVISAR';
  bool get esNoProcede => resultado == 'NO PROCEDE';

  factory PreEvaluacionResultadoModel.fromJson(
    Map<String, dynamic> json, {
    bool desdeCola = false,
  }) {
    return PreEvaluacionResultadoModel(
      resultado: json['resultado']?.toString() ?? 'REVISAR',
      mensaje: json['mensaje']?.toString() ?? '',
      ratioDeudaIngreso: _toNullableDouble(json['ratio_deuda_ingreso']),
      desdeCola: desdeCola,
    );
  }

  static double? _toNullableDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}

/// Datos del prospecto para prellenar solicitud formal.
class ProspectoSolicitudPrefill {
  final String dni;
  final String nombres;
  final String tiponegocio;
  final double ingresos;
  final String destino;
  final double monto;

  const ProspectoSolicitudPrefill({
    required this.dni,
    required this.nombres,
    required this.tiponegocio,
    required this.ingresos,
    required this.destino,
    required this.monto,
  });
}
