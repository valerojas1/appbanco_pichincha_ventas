import '../core/cartera_nivel_prioridad.dart';

class CarteraDiariaModel {
  final String id;
  final String asesorid;
  final String nombrecliente;
  final String documento;
  final String tipogestion;
  final double monto;
  final int prioridadServidor;
  final String fechaasignacion;
  final String estadovisita;
  final bool moraactiva;
  final int diasenmora;
  final String? direccion;
  final String? telefono;
  final double? latitud;
  final double? longitud;
  final String? clienteid;
  final int scorePrioridad;

  CarteraDiariaModel({
    required this.id,
    required this.asesorid,
    required this.nombrecliente,
    required this.documento,
    required this.tipogestion,
    required this.monto,
    required this.prioridadServidor,
    required this.fechaasignacion,
    required this.estadovisita,
    required this.moraactiva,
    required this.diasenmora,
    this.direccion,
    this.telefono,
    this.latitud,
    this.longitud,
    this.clienteid,
    required this.scorePrioridad,
  });

  bool get esVisitado => estadovisita == 'visitado';

  bool get tieneCoordenadas => latitud != null && longitud != null;

  NivelPrioridad get nivelPrioridad =>
      CarteraNivelPrioridad.desdeScore(scorePrioridad);

  bool get esMora =>
      moraactiva || tipogestion == 'RECUPERACION MORA';

  String get documentoCensurado {
    final doc = documento.replaceAll(RegExp(r'\D'), '');
    if (doc.length <= 4) return '****$doc';
    return '******${doc.substring(doc.length - 4)}';
  }

  factory CarteraDiariaModel.fromJson(
    Map<String, dynamic> json, {
    int scorePrioridad = 0,
  }) {
    return CarteraDiariaModel(
      id: json['id']?.toString() ?? '',
      asesorid: json['asesorid']?.toString() ?? '',
      nombrecliente: json['nombrecliente'] ?? '',
      documento: json['documento'] ?? '',
      tipogestion: (json['tipogestion'] ?? '').toString().toUpperCase(),
      monto: _toDouble(json['monto']),
      prioridadServidor: _toInt(json['prioridad']),
      fechaasignacion: json['fechaasignacion']?.toString() ?? '',
      estadovisita: json['estadovisita'] ?? 'pendiente',
      moraactiva: json['moraactiva'] == true,
      diasenmora: _toInt(json['diasenmora']),
      direccion: json['direccion'],
      telefono: json['telefono'],
      latitud: _toNullableDouble(json['latitud']),
      longitud: _toNullableDouble(json['longitud']),
      clienteid: json['clienteid']?.toString(),
      scorePrioridad: scorePrioridad,
    );
  }

  CarteraDiariaModel copyWith({
    String? estadovisita,
    int? scorePrioridad,
    String? direccion,
    double? latitud,
    double? longitud,
    String? clienteid,
  }) {
    return CarteraDiariaModel(
      id: id,
      asesorid: asesorid,
      nombrecliente: nombrecliente,
      documento: documento,
      tipogestion: tipogestion,
      monto: monto,
      prioridadServidor: prioridadServidor,
      fechaasignacion: fechaasignacion,
      estadovisita: estadovisita ?? this.estadovisita,
      moraactiva: moraactiva,
      diasenmora: diasenmora,
      direccion: direccion ?? this.direccion,
      telefono: telefono,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      clienteid: clienteid ?? this.clienteid,
      scorePrioridad: scorePrioridad ?? this.scorePrioridad,
    );
  }

  static double? _toNullableDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }
}
