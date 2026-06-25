/// Formato de fechas para la UI (Perú: dd/MM/yyyy).
class FormatoFecha {
  static String corta(DateTime? fecha) {
    if (fecha == null) return '—';
    final local = fecha.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    return '$dd/$mm/${local.year}';
  }

  static String cortaConHora(DateTime? fecha) {
    if (fecha == null) return '—';
    final local = fecha.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '${corta(local)} $hh:$min';
  }

  /// Fecha de vencimiento de la cuota [numero] (1-based) según día de pago.
  static DateTime vencimientoCuota({
    required DateTime fechaReferencia,
    required int diaPago,
    required int numeroCuota,
  }) {
    final dia = diaPago.clamp(1, 28);
    var month = fechaReferencia.month + numeroCuota;
    var year = fechaReferencia.year;
    while (month > 12) {
      month -= 12;
      year++;
    }
    return DateTime(year, month, dia);
  }
}
