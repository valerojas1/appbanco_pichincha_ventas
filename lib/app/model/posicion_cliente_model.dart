import 'cliente_ficha_model.dart';

class PosicionClienteModel {
  final double deudaTotal;
  final int cuentasVigentes;
  final int cuentasEnMora;
  final int diasMayorMora;
  final String? fechaUltimoPago;
  final bool desdeCache;

  PosicionClienteModel({
    required this.deudaTotal,
    required this.cuentasVigentes,
    required this.cuentasEnMora,
    required this.diasMayorMora,
    this.fechaUltimoPago,
    this.desdeCache = false,
  });

  factory PosicionClienteModel.fromEdgeJson(
    Map<String, dynamic> json, {
    bool desdeCache = false,
  }) {
    return PosicionClienteModel(
      deudaTotal: _toDouble(json['deuda_total'] ?? json['deudatotal']),
      cuentasVigentes:
          _toInt(json['cuentas_vigentes'] ?? json['cuentasvigentes']),
      cuentasEnMora: _toInt(json['cuentas_en_mora'] ?? json['cuentasenmora']),
      diasMayorMora:
          _toInt(json['dias_mayor_mora'] ?? json['diasmayormora']),
      fechaUltimoPago: (json['fecha_ultimo_pago'] ?? json['fechaultimopago'])
          ?.toString(),
      desdeCache: desdeCache,
    );
  }

  factory PosicionClienteModel.fromCliente(ClienteFichaModel c) {
    return PosicionClienteModel(
      deudaTotal: c.deudatotal,
      cuentasVigentes: c.cuentasvigentes,
      cuentasEnMora: c.cuentasenmora,
      diasMayorMora: c.diasmayormora,
      fechaUltimoPago: c.fechaultimopago,
      desdeCache: true,
    );
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }
}
