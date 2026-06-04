class ProductividadAsesorModel {
  final String asesorid;
  final String nombreAsesor;
  final int enviadas;
  final int aprobadas;
  final int desembolsadas;
  final double montoDesembolsado;
  final double tasaAprobacion;

  ProductividadAsesorModel({
    required this.asesorid,
    required this.nombreAsesor,
    required this.enviadas,
    required this.aprobadas,
    required this.desembolsadas,
    required this.montoDesembolsado,
    required this.tasaAprobacion,
  });
}
