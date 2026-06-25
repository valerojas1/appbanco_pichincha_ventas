import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/estado_solicitud.dart';
import '../model/solicitud_resumen_model.dart';
import '../model/tipo_documento_config.dart';

class AdminSolicitudDocsResumen {
  final String solicitudId;
  final String nombres;
  final String apellidos;
  final double monto;
  final String? estado;
  final String? asesorId;
  final DateTime? createdAt;
  final int documentosSubidos;
  final int documentosObligatorios;

  AdminSolicitudDocsResumen({
    required this.solicitudId,
    required this.nombres,
    required this.apellidos,
    required this.monto,
    this.estado,
    this.asesorId,
    this.createdAt,
    required this.documentosSubidos,
    required this.documentosObligatorios,
  });

  String get nombreCliente => '$nombres $apellidos'.trim();

  bool get documentacionCompleta =>
      documentosSubidos >= documentosObligatorios;

  factory AdminSolicitudDocsResumen.fromJson(Map<String, dynamic> json) {
    final docs = json['solicitudesdocumentos'];
    final listaDocs = docs is List ? docs : <dynamic>[];
    final obligatorios = TipoDocumentoConfig.catalogo
        .where((t) => t.obligatorio)
        .length;

    return AdminSolicitudDocsResumen(
      solicitudId: json['id']?.toString() ?? '',
      nombres: json['nombres']?.toString() ?? '',
      apellidos: json['apellidos']?.toString() ?? '',
      monto: _toDouble(json['monto']),
      estado: json['estado']?.toString(),
      asesorId: json['asesorid']?.toString(),
      createdAt: DateTime.tryParse(json['createdat']?.toString() ?? ''),
      documentosSubidos: listaDocs.length,
      documentosObligatorios: obligatorios,
    );
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }
}

class AdminWebService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<AdminSolicitudDocsResumen>> listarSolicitudesConDocumentos({
    int limit = 50,
  }) async {
    try {
      final rows = await _client
          .from('solicitudescredito')
          .select(
            'id, nombres, apellidos, monto, estado, asesorid, createdat, '
            'solicitudesdocumentos(id)',
          )
          .not('estado', 'eq', 'borrador')
          .order('createdat', ascending: false)
          .limit(limit);

      return (rows as List)
          .map((r) => AdminSolicitudDocsResumen.fromJson(
                Map<String, dynamic>.from(r as Map),
              ))
          .where((s) => s.documentosSubidos > 0)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<SolicitudResumenModel>> listarSolicitudesPorTab({
    required TabSolicitud tab,
    int limit = 50,
  }) async {
    try {
      final rows = await _client
          .from('solicitudescredito')
          .select(
            'id, nombres, apellidos, monto, estado, numeroexpediente, '
            'analistaasignado, fechaeenvio, createdat',
          )
          .inFilter('estado', tab.estadosDb)
          .order('fechaeenvio', ascending: false)
          .limit(limit);

      return (rows as List)
          .map((r) => SolicitudResumenModel.fromJson(
                Map<String, dynamic>.from(r as Map),
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<Map<TabSolicitud, int>> contarSolicitudesPorTab() async {
    final map = <TabSolicitud, int>{};
    for (final tab in TabSolicitud.values) {
      try {
        final rows = await _client
            .from('solicitudescredito')
            .select('id')
            .inFilter('estado', tab.estadosDb);
        map[tab] = (rows as List).length;
      } catch (_) {
        map[tab] = 0;
      }
    }
    return map;
  }

  Future<AdminInicioResumen> obtenerResumenInicio() async {
    final docs = await listarSolicitudesConDocumentos(limit: 100);
    final contadores = await contarSolicitudesPorTab();

    final pendientesRevision = docs
        .where((d) => !d.documentacionCompleta || d.estado == 'completa')
        .length;

    return AdminInicioResumen(
      solicitudesConDocumentos: docs.length,
      pendientesRevision: pendientesRevision,
      solicitudesRecibidas: contadores[TabSolicitud.recibidas] ?? 0,
      solicitudesEnEvaluacion: contadores[TabSolicitud.enEvaluacion] ?? 0,
      solicitudesEnviadas: contadores[TabSolicitud.enviadas] ?? 0,
      solicitudesEnComite: contadores[TabSolicitud.enComite] ?? 0,
      solicitudesAprobadas: contadores[TabSolicitud.aprobadas] ?? 0,
      solicitudesCondicionadas: contadores[TabSolicitud.condicionadas] ?? 0,
    );
  }
}

class AdminInicioResumen {
  final int solicitudesConDocumentos;
  final int pendientesRevision;
  final int solicitudesRecibidas;
  final int solicitudesEnEvaluacion;
  final int solicitudesEnviadas;
  final int solicitudesEnComite;
  final int solicitudesAprobadas;
  final int solicitudesCondicionadas;

  const AdminInicioResumen({
    required this.solicitudesConDocumentos,
    required this.pendientesRevision,
    required this.solicitudesRecibidas,
    required this.solicitudesEnEvaluacion,
    required this.solicitudesEnviadas,
    required this.solicitudesEnComite,
    required this.solicitudesAprobadas,
    required this.solicitudesCondicionadas,
  });
}
