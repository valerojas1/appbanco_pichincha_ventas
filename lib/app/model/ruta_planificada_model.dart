class RutaPlanificadaModel {
  final String rutaid;
  final String asesorid;
  final String clienteid;
  final String nombrecliente;
  final String direccion;
  final String tipogestion;
  final String estadovisita;
  final DateTime? fecharuta;
  final String? observaciones;

  RutaPlanificadaModel({
    required this.rutaid,
    required this.asesorid,
    required this.clienteid,
    required this.nombrecliente,
    required this.direccion,
    required this.tipogestion,
    required this.estadovisita,
    this.fecharuta,
    this.observaciones,
  });

  factory RutaPlanificadaModel.fromJson(Map<String, dynamic> json) {
    return RutaPlanificadaModel(
      rutaid: json['rutaid'] ?? '',
      asesorid: json['asesorid'] ?? '',
      clienteid: json['clienteid'] ?? '',
      nombrecliente: json['nombrecliente'] ?? '',
      direccion: json['direccion'] ?? '',
      tipogestion: json['tipogestion'] ?? '',
      estadovisita: json['estadovisita'] ?? '',
      fecharuta: json['fecharuta'] != null ? DateTime.tryParse(json['fecharuta']) : null,
      observaciones: json['observaciones'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rutaid': rutaid,
      'asesorid': asesorid,
      'clienteid': clienteid,
      'nombrecliente': nombrecliente,
      'direccion': direccion,
      'tipogestion': tipogestion,
      'estadovisita': estadovisita,
      'fecharuta': fecharuta?.toIso8601String(),
      'observaciones': observaciones,
    };
  }
}
