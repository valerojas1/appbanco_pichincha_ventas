class ClienteFinancieroModel {
  final String perfilid;
  final String userid;
  final String nombres;
  final String apellidos;
  final String dni;
  final String estadocliente;
  final String tiponegocio;
  final int antiguedadnegocio;
  final bool localpropio;
  final String zonanegocio;
  final double ingresomensualest;
  final double gastomensualest;
  final double deudaactual;
  final int entidadesdeuda;
  final double puntajecrediticio;
  final String? telefono;
  final String? email;
  final double? scoretransaccional;
  final String? segmento;
  final double? montomaxsugerido;
  final String? recomendacion;
  final double? capacidadpago;
  final double? ratiodeudaingreso;
  final double? promediosaldo3m;
  final double? variabilidadsaldo;
  final double? porcentajepagospuntual;
  final double flujonetoestimado;

  ClienteFinancieroModel({
    required this.perfilid,
    required this.userid,
    required this.nombres,
    required this.apellidos,
    required this.dni,
    required this.estadocliente,
    required this.tiponegocio,
    required this.antiguedadnegocio,
    required this.localpropio,
    required this.zonanegocio,
    required this.ingresomensualest,
    required this.gastomensualest,
    required this.deudaactual,
    required this.entidadesdeuda,
    required this.puntajecrediticio,
    this.telefono,
    this.email,
    this.scoretransaccional,
    this.segmento,
    this.montomaxsugerido,
    this.recomendacion,
    this.capacidadpago,
    this.ratiodeudaingreso,
    this.promediosaldo3m,
    this.variabilidadsaldo,
    this.porcentajepagospuntual,
    required this.flujonetoestimado,
  });

  String get nombreCompleto => '$nombres $apellidos'.trim();

  bool get esProspecto => estadocliente == 'prospecto';

  bool get tieneScoring => scoretransaccional != null && scoretransaccional! > 0;

  factory ClienteFinancieroModel.fromJson(Map<String, dynamic> json) {
    return ClienteFinancieroModel(
      perfilid: json['perfilid']?.toString() ?? '',
      userid: json['userid']?.toString() ?? '',
      nombres: json['nombres'] ?? '',
      apellidos: json['apellidos'] ?? '',
      dni: json['dni'] ?? '',
      estadocliente: json['estadocliente'] ?? '',
      tiponegocio: json['tiponegocio'] ?? '',
      antiguedadnegocio: _toInt(json['antiguedadnegocio']),
      localpropio: json['localpropio'] == true,
      zonanegocio: json['zonanegocio'] ?? '',
      ingresomensualest: _toDouble(json['ingresomensualest']),
      gastomensualest: _toDouble(json['gastomensualest']),
      deudaactual: _toDouble(json['deudaactual']),
      entidadesdeuda: _toInt(json['entidadesdeuda']),
      puntajecrediticio: _toDouble(json['puntajecrediticio']),
      telefono: json['telefono'],
      email: json['email'],
      scoretransaccional: _toNullableDouble(json['scoretransaccional']),
      segmento: json['segmento'],
      montomaxsugerido: _toNullableDouble(json['montomaxsugerido']),
      recomendacion: json['recomendacion'],
      capacidadpago: _toNullableDouble(json['capacidadpago']),
      ratiodeudaingreso: _toNullableDouble(json['ratiodeudaingreso']),
      promediosaldo3m: _toNullableDouble(json['promediosaldo3m']),
      variabilidadsaldo: _toNullableDouble(json['variabilidadsaldo']),
      porcentajepagospuntual: _toNullableDouble(json['porcentajepagospuntual']),
      flujonetoestimado: _toDouble(json['flujonetoestimado']),
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static double? _toNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
