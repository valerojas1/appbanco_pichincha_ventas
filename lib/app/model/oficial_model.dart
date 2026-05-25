class OficialModel {
  final String userid;
  final String nombre;
  final String apellido;
  final String codigoempleado;
  final String dni;
  final String email;
  final String zona;
  final String rol;

  OficialModel({
    required this.userid,
    required this.nombre,
    required this.apellido,
    required this.codigoempleado,
    required this.dni,
    required this.email,
    required this.zona,
    required this.rol,
  });

  factory OficialModel.fromJson(Map<String, dynamic> json) {
    return OficialModel(
      userid: json['userid'] ?? '',
      nombre: json['nombre'] ?? '',
      apellido: json['apellido'] ?? '',
      codigoempleado: json['codigoempleado'] ?? '',
      dni: json['dni'] ?? '',
      email: json['email'] ?? '',
      zona: json['zona'] ?? '',
      rol: json['rol'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userid': userid,
      'nombre': nombre,
      'apellido': apellido,
      'codigoempleado': codigoempleado,
      'dni': dni,
      'email': email,
      'zona': zona,
      'rol': rol,
    };
  }
}
