class AsesorMonitorResumen {
  final String asesorid;
  final String nombreAsesor;
  final int total;
  final int visitados;
  final double? latitud;
  final double? longitud;
  final DateTime? ultimaActualizacion;

  AsesorMonitorResumen({
    required this.asesorid,
    required this.nombreAsesor,
    required this.total,
    required this.visitados,
    this.latitud,
    this.longitud,
    this.ultimaActualizacion,
  });

  double get progreso => total == 0 ? 0 : visitados / total;
}
