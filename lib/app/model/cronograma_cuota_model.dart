/// Fila del cronograma de amortización francesa.
class CronogramaCuotaModel {
  final int numero;
  final double cuota;
  final double capital;
  final double interes;
  final double saldo;
  final DateTime? fechaVencimiento;

  const CronogramaCuotaModel({
    required this.numero,
    required this.cuota,
    required this.capital,
    required this.interes,
    required this.saldo,
    this.fechaVencimiento,
  });
}

/// Catálogo de casos condicionados del comité (25, 26, 27).
class CasoCondicionado {
  final String codigo;
  final String titulo;
  final String descripcion;

  const CasoCondicionado({
    required this.codigo,
    required this.titulo,
    required this.descripcion,
  });

  static const catalogo = [
    CasoCondicionado(
      codigo: '25',
      titulo: 'Caso 25 — Capacidad de pago',
      descripcion: 'Monto aprobado menor por capacidad de pago limitada.',
    ),
    CasoCondicionado(
      codigo: '26',
      titulo: 'Caso 26 — Historial crediticio',
      descripcion: 'Monto aprobado menor por historial crediticio observado.',
    ),
    CasoCondicionado(
      codigo: '27',
      titulo: 'Caso 27 — Garantías insuficientes',
      descripcion: 'Monto aprobado menor por garantías insuficientes.',
    ),
  ];

  static CasoCondicionado? porCodigo(String? codigo) {
    if (codigo == null) return null;
    for (final c in catalogo) {
      if (c.codigo == codigo) return c;
    }
    return null;
  }
}
