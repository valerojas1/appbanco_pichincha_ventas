class SolicitudNotaInternaModel {
  final String id;
  final String solicitudId;
  final String asesorId;
  final String autorNombre;
  final String perfilAutor;
  final String contenido;
  final DateTime createdAt;

  SolicitudNotaInternaModel({
    required this.id,
    required this.solicitudId,
    required this.asesorId,
    required this.autorNombre,
    required this.perfilAutor,
    required this.contenido,
    required this.createdAt,
  });

  factory SolicitudNotaInternaModel.fromJson(Map<String, dynamic> json) {
    return SolicitudNotaInternaModel(
      id: json['id']?.toString() ?? '',
      solicitudId: json['solicitudid']?.toString() ?? '',
      asesorId: json['asesorid']?.toString() ?? '',
      autorNombre: json['autornombre']?.toString() ?? '',
      perfilAutor: json['perfilautor']?.toString() ?? 'operador',
      contenido: json['contenido']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdat']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
