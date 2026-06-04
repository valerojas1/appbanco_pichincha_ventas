import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/alerta_cartera_model.dart';
import '../model/cliente_ficha_model.dart';
import '../model/credito_historial_model.dart';
import '../model/oferta_preaprobada_model.dart';
import '../model/pago_mensual_model.dart';
import '../model/posicion_cliente_model.dart';
import 'ficha_cliente_offline_db.dart';

class FichaClienteService {
  final SupabaseClient _client = Supabase.instance.client;
  final FichaClienteOfflineDb _offlineDb = FichaClienteOfflineDb();
  final Connectivity _connectivity = Connectivity();

  Future<bool> get hayConexion async {
    final r = await _connectivity.checkConnectivity();
    return r.isNotEmpty && !r.contains(ConnectivityResult.none);
  }

  Future<ClienteFichaModel?> obtenerCliente({
    String? clienteid,
    String? documento,
  }) async {
    try {
      var q = _client.from('clientes').select();
      if (clienteid != null && clienteid.isNotEmpty) {
        q = q.eq('id', clienteid);
      } else if (documento != null && documento.isNotEmpty) {
        q = q.eq('documento', documento);
      } else {
        return null;
      }
      final row = await q.maybeSingle();
      if (row == null) return null;
      return ClienteFichaModel.fromJson(Map<String, dynamic>.from(row));
    } catch (_) {
      return null;
    }
  }

  Future<PosicionClienteModel?> consultarPosicion({
    String? clienteid,
    String? documento,
    ClienteFichaModel? clienteCache,
  }) async {
    if (!await hayConexion) {
      if (clienteCache != null) {
        return PosicionClienteModel.fromCliente(clienteCache);
      }
      return null;
    }
    try {
      final body = <String, dynamic>{};
      if (clienteid != null && clienteid.isNotEmpty) {
        body['clienteid'] = clienteid;
      } else if (documento != null && documento.isNotEmpty) {
        body['documento'] = documento;
      } else {
        return null;
      }
      final res = await _client.functions.invoke(
        'consulta-posicion',
        body: body,
      );
      final data = res.data;
      if (data is Map) {
        return PosicionClienteModel.fromEdgeJson(
          Map<String, dynamic>.from(data),
        );
      }
    } catch (_) {}
    if (clienteCache != null) {
      return PosicionClienteModel.fromCliente(clienteCache);
    }
    return null;
  }

  Future<List<CreditoHistorialModel>> ultimosCreditos(
    String clienteid, {
    int limite = 5,
  }) async {
    try {
      final rows = await _client
          .from('creditos')
          .select()
          .eq('clienteid', clienteid)
          .order('fechadesembolso', ascending: false)
          .limit(limite);
      return (rows as List)
          .map((e) => CreditoHistorialModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<PagoMensualModel>> pagosDoceMeses(String clienteid) async {
    try {
      final rows = await _client
          .from('pagosmensuales')
          .select()
          .eq('clienteid', clienteid)
          .order('periodo', ascending: true);
      final lista = (rows as List)
          .map((e) => PagoMensualModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();
      if (lista.length <= 12) return lista;
      return lista.sublist(lista.length - 12);
    } catch (_) {
      return [];
    }
  }

  Future<OfertaPreaprobadaModel?> ofertaVigente(String clienteid) async {
    try {
      final hoy = DateTime.now().toIso8601String().split('T').first;
      final row = await _client
          .from('creditospreaprobados')
          .select()
          .eq('clienteid_ficha', clienteid)
          .eq('vigente', true)
          .gte('fechavencimiento', hoy)
          .order('scoreaprobacion', ascending: false)
          .limit(1)
          .maybeSingle();
      if (row == null) return null;
      return OfertaPreaprobadaModel.fromJson(
        Map<String, dynamic>.from(row),
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<AlertaCarteraModel>> alertasPorAsesor(String asesorid) async {
    try {
      final rows = await _client
          .from('alertascartera')
          .select()
          .eq('asesorid', asesorid)
          .order('createdat', ascending: false)
          .limit(50);
      return (rows as List)
          .map((e) => AlertaCarteraModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Carga bundle completo (online u offline).
  Future<Map<String, dynamic>?> cargarBundle({
    required String? clienteid,
    required String documento,
    required String asesorid,
  }) async {
    final online = await hayConexion;
    ClienteFichaModel? cliente;
    List<CreditoHistorialModel> creditos = [];
    List<PagoMensualModel> pagos = [];
    OfertaPreaprobadaModel? oferta;
    PosicionClienteModel? posicion;

    if (clienteid != null && clienteid.isNotEmpty) {
      final cache = await _offlineDb.leerFicha(clienteid);
      if (!online && cache != null) {
        return cache;
      }
    }

    if (online) {
      cliente = await obtenerCliente(
        clienteid: clienteid,
        documento: documento,
      );
      if (cliente == null) return null;
      final cid = cliente.id;
      creditos = await ultimosCreditos(cid);
      pagos = await pagosDoceMeses(cid);
      oferta = await ofertaVigente(cid);
      posicion = await consultarPosicion(
        clienteid: cid,
        clienteCache: cliente,
      );
      final bundle = {
        'cliente': cliente.toJson(),
        'creditos': creditos.map((c) => c.toJson()).toList(),
        'pagos': pagos.map((p) => p.toJson()).toList(),
        'oferta': oferta?.toJson(),
        'posicion': posicion != null
            ? {
                'deuda_total': posicion.deudaTotal,
                'cuentas_vigentes': posicion.cuentasVigentes,
                'cuentas_en_mora': posicion.cuentasEnMora,
                'dias_mayor_mora': posicion.diasMayorMora,
                'fecha_ultimo_pago': posicion.fechaUltimoPago,
              }
            : null,
      };
      await _offlineDb.guardarFicha(
        clienteid: cid,
        asesorid: asesorid,
        payload: bundle,
      );
      return bundle;
    }

    if (clienteid != null) {
      return _offlineDb.leerFicha(clienteid);
    }
    return null;
  }

  /// Sincronización nocturna: descarga todos los clientes del asesor.
  Future<int> sincronizarCarteraAsesor(String asesorid) async {
    if (!await hayConexion) return 0;
    int count = 0;
    try {
      final clientes = await _client
          .from('clientes')
          .select()
          .eq('asesorid', asesorid);
      for (final raw in clientes as List) {
        final c = ClienteFichaModel.fromJson(
          Map<String, dynamic>.from(raw as Map),
        );
        await cargarBundle(
          clienteid: c.id,
          documento: c.documento,
          asesorid: asesorid,
        );
        count++;
      }
      await _offlineDb.marcarSyncAsesor(asesorid);
    } catch (_) {}
    return count;
  }

  RealtimeChannel suscribirAlertas({
    required String asesorid,
    required void Function(AlertaCarteraModel) onNueva,
  }) {
    return _client
        .channel('alertas_cartera_$asesorid')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'alertascartera',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'asesorid',
            value: asesorid,
          ),
          callback: (payload) {
            final n = payload.newRecord;
            if (n.isNotEmpty) {
              onNueva(AlertaCarteraModel.fromJson(
                Map<String, dynamic>.from(n),
              ));
            }
          },
        )
        .subscribe();
  }
}
