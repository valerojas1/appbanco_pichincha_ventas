class ClienteCarteraModel {
  final String clienteid;
  final String nombre;
  final String apellido;
  final String dni;
  final String direccion;
  final String tipogestion;
  final String estado;
  final String? telefonocontacto;

  ClienteCarteraModel({
    required this.clienteid,
    required this.nombre,
    required this.apellido,
    required this.dni,
    required this.direccion,
    required this.tipogestion,
    required this.estado,
    this.telefonocontacto,
  });

  factory ClienteCarteraModel.fromJson(Map<String, dynamic> json) {
    return ClienteCarteraModel(
      clienteid: json['clienteid'] ?? '',
      nombre: json['nombre'] ?? '',
      apellido: json['apellido'] ?? '',
      dni: json['dni'] ?? '',
      direccion: json['direccion'] ?? '',
      tipogestion: json['tipogestion'] ?? '',
      estado: json['estado'] ?? '',
      telefonocontacto: json['telefonocontacto'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clienteid': clienteid,
      'nombre': nombre,
      'apellido': apellido,
      'dni': dni,
      'direccion': direccion,
      'tipogestion': tipogestion,
      'estado': estado,
      'telefonocontacto': telefonocontacto,
    };
  }
}
