import 'dart:convert';
import 'perfil_oficial.dart';

class OficialModel {
  final String userid;
  final String nombre;
  final String apellido;
  final String dni;
  final String email;
  final String asesorid;
  final String codigoasesor;
  final String codigoempleado;
  final String zonaasignada;
  final String especialidad;
  final PerfilOficial perfil;
  final String? authUserId;
  final String? telefono;

  OficialModel({
    required this.userid,
    required this.nombre,
    required this.apellido,
    required this.dni,
    required this.email,
    required this.asesorid,
    required this.codigoasesor,
    required this.codigoempleado,
    required this.zonaasignada,
    required this.especialidad,
    required this.perfil,
    this.authUserId,
    this.telefono,
  });

  factory OficialModel.fromJson(Map<String, dynamic> json) {
    return OficialModel(
      userid: json['userid']?.toString() ?? json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? '',
      apellido: json['apellido'] ?? '',
      dni: json['dni'] ?? '',
      email: json['email'] ?? '',
      asesorid: json['asesorid']?.toString() ?? '',
      codigoasesor: json['codigoasesor'] ?? '',
      codigoempleado: json['codigoempleado'] ?? '',
      zonaasignada: json['zonaasignada'] ?? '',
      especialidad: json['especialidad'] ?? '',
      perfil: PerfilOficial.fromString(json['perfil'] ?? 'operador'),
      authUserId: json['auth_user_id']?.toString(),
      telefono: json['telefono'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userid': userid,
      'nombre': nombre,
      'apellido': apellido,
      'dni': dni,
      'email': email,
      'asesorid': asesorid,
      'codigoasesor': codigoasesor,
      'codigoempleado': codigoempleado,
      'zonaasignada': zonaasignada,
      'especialidad': especialidad,
      'perfil': perfil.name,
      'auth_user_id': authUserId,
      'telefono': telefono,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  static OficialModel? fromJsonString(String raw) {
    try {
      return OficialModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
