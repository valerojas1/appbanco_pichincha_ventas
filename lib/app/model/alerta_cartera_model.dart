class AlertaCarteraModel {
  final String id;
  final String asesorid;
  final String? clienteid;
  final String titulo;
  final String mensaje;
  final String severidad;
  final bool leida;
  final String? createdat;

  AlertaCarteraModel({
    required this.id,
    required this.asesorid,
    this.clienteid,
    required this.titulo,
    required this.mensaje,
    required this.severidad,
    required this.leida,
    this.createdat,
  });

  factory AlertaCarteraModel.fromJson(Map<String, dynamic> json) {
    return AlertaCarteraModel(
      id: json['id']?.toString() ?? '',
      asesorid: json['asesorid']?.toString() ?? '',
      clienteid: json['clienteid']?.toString(),
      titulo: json['titulo']?.toString() ?? '',
      mensaje: json['mensaje']?.toString() ?? '',
      severidad: json['severidad']?.toString() ?? 'info',
      leida: json['leida'] == true,
      createdat: json['createdat']?.toString(),
    );
  }
}
