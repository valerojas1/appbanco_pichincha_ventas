import 'dart:math' as math;

/// Simulador de cuota con amortización francesa.
/// TM = (1 + TEA)^(1/12) - 1
/// Cuota = Monto × [TM / (1 - (1+TM)^(-n))]
class AmortizacionFrancesa {
  static double tasaMensualDesdeTea(double teaPorcentaje) {
    final tea = teaPorcentaje / 100;
    return math.pow(1 + tea, 1 / 12).toDouble() - 1;
  }

  static double calcularCuota({
    required double monto,
    required double teaPorcentaje,
    required int plazoMeses,
  }) {
    if (plazoMeses <= 0 || monto <= 0) return 0;
    final tm = tasaMensualDesdeTea(teaPorcentaje);
    if (tm.abs() < 1e-12) return monto / plazoMeses;
    final factor = 1 - math.pow(1 + tm, -plazoMeses);
    if (factor.abs() < 1e-12) return monto / plazoMeses;
    return monto * (tm / factor);
  }

  static double totalAPagar({
    required double cuotaMensual,
    required int plazoMeses,
  }) => cuotaMensual * plazoMeses;

  static double totalIntereses({
    required double monto,
    required double totalPagar,
  }) => math.max(0, totalPagar - monto);
}
