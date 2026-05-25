class OficialModel {
  final String userid;
  final String nombre;
  final String apellido;
  final String dni;
  final String email;
  final String rol;
  final String asesorid;
  final String codigoasesor;
  final String zonaasignada;
  final String especialidad;

  OficialModel({
    required this.userid,
    required this.nombre,
    required this.apellido,
    required this.dni,
    required this.email,
    required this.rol,
    required this.asesorid,
    required this.codigoasesor,
    required this.zonaasignada,
    required this.especialidad,
  });

  factory OficialModel.fromJson(Map<String, dynamic> json) {
    return OficialModel(
      userid: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      apellido: json['apellido'] ?? '',
      dni: json['dni'] ?? '',
      email: json['email'] ?? '',
      rol: json['rol'] ?? '',
      asesorid: json['asesorid'] ?? '',
      codigoasesor: json['codigoasesor'] ?? '',
      zonaasignada: json['zonaasignada'] ?? '',
      especialidad: json['especialidad'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': userid,
      'nombre': nombre,
      'apellido': apellido,
      'dni': dni,
      'email': email,
      'rol': rol,
      'asesorid': asesorid,
      'codigoasesor': codigoasesor,
      'zonaasignada': zonaasignada,
      'especialidad': especialidad,
    };
  }
}
