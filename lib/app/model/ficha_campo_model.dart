class FichaCampoModel {
  final String fichaid;
  final String asesorid;
  final String clienteid;
  final String nombrecliente;
  final String apellidocliente;
  final String dnifliente;
  final String direccion;
  final String telefonocontacto;
  final String tiponegocio;
  final double ingresomensual;
  final double gastosmensuales;
  final String referencias;
  final String observaciones;
  final String estadoficha;
  final double? montosugerido;
  final String? latitud;
  final String? longitud;
  final DateTime? createdat;

  FichaCampoModel({
    required this.fichaid,
    required this.asesorid,
    required this.clienteid,
    required this.nombrecliente,
    required this.apellidocliente,
    required this.dnifliente,
    required this.direccion,
    required this.telefonocontacto,
    required this.tiponegocio,
    required this.ingresomensual,
    required this.gastosmensuales,
    required this.referencias,
    required this.observaciones,
    required this.estadoficha,
    this.montosugerido,
    this.latitud,
    this.longitud,
    this.createdat,
  });

  factory FichaCampoModel.fromJson(Map<String, dynamic> json) {
    return FichaCampoModel(
      fichaid: json['fichaid'] ?? '',
      asesorid: json['asesorid'] ?? '',
      clienteid: json['clienteid'] ?? '',
      nombrecliente: json['nombrecliente'] ?? '',
      apellidocliente: json['apellidocliente'] ?? '',
      dnifliente: json['dnifliente'] ?? '',
      direccion: json['direccion'] ?? '',
      telefonocontacto: json['telefonocontacto'] ?? '',
      tiponegocio: json['tiponegocio'] ?? '',
      ingresomensual: (json['ingresomensual'] ?? 0).toDouble(),
      gastosmensuales: (json['gastosmensuales'] ?? 0).toDouble(),
      referencias: json['referencias'] ?? '',
      observaciones: json['observaciones'] ?? '',
      estadoficha: json['estadoficha'] ?? 'borrador',
      montosugerido: (json['montosugerido'] as num?)?.toDouble(),
      latitud: json['latitud'],
      longitud: json['longitud'],
      createdat: json['createdat'] != null ? DateTime.tryParse(json['createdat']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fichaid': fichaid,
      'asesorid': asesorid,
      'clienteid': clienteid,
      'nombrecliente': nombrecliente,
      'apellidocliente': apellidocliente,
      'dnifliente': dnifliente,
      'direccion': direccion,
      'telefonocontacto': telefonocontacto,
      'tiponegocio': tiponegocio,
      'ingresomensual': ingresomensual,
      'gastosmensuales': gastosmensuales,
      'referencias': referencias,
      'observaciones': observaciones,
      'estadoficha': estadoficha,
      'montosugerido': montosugerido,
      'latitud': latitud,
      'longitud': longitud,
      'createdat': createdat?.toIso8601String(),
    };
  }
}
