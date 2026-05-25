class DashboardAsesorModel {
  final String asesorid;
  final String nombreasesor;
  final int visitashoy;
  final int visitascompletadas;
  final int creditoscolocados;
  final double montocolocado;
  final int clientesnuevos;
  final int solicitudespendientes;

  DashboardAsesorModel({
    required this.asesorid,
    required this.nombreasesor,
    required this.visitashoy,
    required this.visitascompletadas,
    required this.creditoscolocados,
    required this.montocolocado,
    required this.clientesnuevos,
    required this.solicitudespendientes,
  });

  factory DashboardAsesorModel.fromJson(Map<String, dynamic> json) {
    return DashboardAsesorModel(
      asesorid: json['asesorid'] ?? '',
      nombreasesor: json['nombreasesor'] ?? '',
      visitashoy: json['visitashoy'] ?? 0,
      visitascompletadas: json['visitascompletadas'] ?? 0,
      creditoscolocados: json['creditoscolocados'] ?? 0,
      montocolocado: (json['montocolocado'] ?? 0).toDouble(),
      clientesnuevos: json['clientesnuevos'] ?? 0,
      solicitudespendientes: json['solicitudespendientes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'asesorid': asesorid,
      'nombreasesor': nombreasesor,
      'visitashoy': visitashoy,
      'visitascompletadas': visitascompletadas,
      'creditoscolocados': creditoscolocados,
      'montocolocado': montocolocado,
      'clientesnuevos': clientesnuevos,
      'solicitudespendientes': solicitudespendientes,
    };
  }
}
