import 'dart:math' as math;

/// Simulador de cuota con amortización francesa.
/// TM = (1 + TEA)^(1/12) - 1
/// Cuota = Monto × [TM / (1 - (1+TM)^(-n))]
class AmortizacionFrancesa {
  static double tasaMensualDesdeTea(double teaPorcentaje) {
    final tea = teaPorcentaje / 100;
    return math.pow(1 + tea, 1 / 12).toDouble() - 1;
  }

  /// Prima mensual referencial de seguro de desgravamen (0.1% del capital).
  static double primaDesgravamenMensual(double monto) => monto * 0.001;

  static double calcularCuota({
    required double monto,
    required double teaPorcentaje,
    required int plazoMeses,
    bool incluyeSeguroDesgravamen = false,
  }) {
    if (plazoMeses <= 0 || monto <= 0) return 0;
    final tm = tasaMensualDesdeTea(teaPorcentaje);
    if (tm.abs() < 1e-12) return monto / plazoMeses;
    final factor = 1 - math.pow(1 + tm, -plazoMeses);
    if (factor.abs() < 1e-12) return monto / plazoMeses;
    final cuotaCredito = monto * (tm / factor);
    if (!incluyeSeguroDesgravamen) return cuotaCredito;
    return cuotaCredito + primaDesgravamenMensual(monto);
  }

  static double totalAPagar({
    required double cuotaMensual,
    required int plazoMeses,
  }) => cuotaMensual * plazoMeses;

  static double totalIntereses({
    required double monto,
    required double totalPagar,
  }) => math.max(0, totalPagar - monto);

  /// Genera tabla de amortización mes a mes.
  static List<({int numero, double cuota, double capital, double interes, double saldo})>
      generarCronograma({
    required double monto,
    required double teaPorcentaje,
    required int plazoMeses,
  }) {
    if (plazoMeses <= 0 || monto <= 0) return [];
    final tm = tasaMensualDesdeTea(teaPorcentaje);
    final cuota = calcularCuota(
      monto: monto,
      teaPorcentaje: teaPorcentaje,
      plazoMeses: plazoMeses,
    );
    var saldo = monto;
    final filas = <({int numero, double cuota, double capital, double interes, double saldo})>[];

    for (var i = 1; i <= plazoMeses; i++) {
      final interes = saldo * tm;
      var capital = cuota - interes;
      if (i == plazoMeses) {
        capital = saldo;
      }
      saldo = math.max(0, saldo - capital);
      filas.add((
        numero: i,
        cuota: cuota,
        capital: capital,
        interes: interes,
        saldo: saldo,
      ));
    }
    return filas;
  }
}
