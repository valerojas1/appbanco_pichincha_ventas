class ClienteFichaModel {
  final String id;
  final String documento;
  final String nombres;
  final String apellidos;
  final String? direccion;
  final String? telefono;
  final String tiponegocio;
  final int antiguedadnegocio;
  final String? fotourl;
  final String clasificacionsbs;
  final String asesorid;
  final double deudatotal;
  final int cuentasvigentes;
  final int cuentasenmora;
  final int diasmayormora;
  final String? fechaultimopago;

  ClienteFichaModel({
    required this.id,
    required this.documento,
    required this.nombres,
    required this.apellidos,
    this.direccion,
    this.telefono,
    required this.tiponegocio,
    required this.antiguedadnegocio,
    this.fotourl,
    required this.clasificacionsbs,
    required this.asesorid,
    required this.deudatotal,
    required this.cuentasvigentes,
    required this.cuentasenmora,
    required this.diasmayormora,
    this.fechaultimopago,
  });

  String get nombreCompleto => '$nombres $apellidos'.trim();

  String get iniciales {
    final n = nombres.isNotEmpty ? nombres[0] : '';
    final a = apellidos.isNotEmpty ? apellidos[0] : '';
    return '$n$a'.toUpperCase();
  }

  factory ClienteFichaModel.fromJson(Map<String, dynamic> json) {
    return ClienteFichaModel(
      id: json['id']?.toString() ?? '',
      documento: json['documento']?.toString() ?? '',
      nombres: json['nombres']?.toString() ?? '',
      apellidos: json['apellidos']?.toString() ?? '',
      direccion: json['direccion']?.toString(),
      telefono: json['telefono']?.toString(),
      tiponegocio: json['tiponegocio']?.toString() ?? '',
      antiguedadnegocio: _toInt(json['antiguedadnegocio']),
      fotourl: json['fotourl']?.toString(),
      clasificacionsbs: json['clasificacionsbs']?.toString() ?? 'Normal',
      asesorid: json['asesorid']?.toString() ?? '',
      deudatotal: _toDouble(json['deudatotal']),
      cuentasvigentes: _toInt(json['cuentasvigentes']),
      cuentasenmora: _toInt(json['cuentasenmora']),
      diasmayormora: _toInt(json['diasmayormora']),
      fechaultimopago: json['fechaultimopago']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'documento': documento,
        'nombres': nombres,
        'apellidos': apellidos,
        'direccion': direccion,
        'telefono': telefono,
        'tiponegocio': tiponegocio,
        'antiguedadnegocio': antiguedadnegocio,
        'fotourl': fotourl,
        'clasificacionsbs': clasificacionsbs,
        'asesorid': asesorid,
        'deudatotal': deudatotal,
        'cuentasvigentes': cuentasvigentes,
        'cuentasenmora': cuentasenmora,
        'diasmayormora': diasmayormora,
        'fechaultimopago': fechaultimopago,
      };

  static int _toInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }
}
