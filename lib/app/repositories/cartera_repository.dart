import '../core/cartera_prioridad_calculator.dart';
import '../core/network_service.dart';
import '../model/cartera_diaria_model.dart';
import '../services/app_local_database.dart';
import '../services/cartera_diaria_service.dart';

class CarteraLoadResult {
  final List<CarteraDiariaModel> items;
  final bool desdeCache;
  final String? aviso;

  CarteraLoadResult({
    required this.items,
    required this.desdeCache,
    this.aviso,
  });
}

/// ViewModel → Repository → red / SQLite (Bloque 10).
class CarteraRepository {
  final CarteraDiariaService _remoto = CarteraDiariaService();
  final AppLocalDatabase _local = AppLocalDatabase.instance;
  final NetworkService _red = NetworkService.instance;

  Future<CarteraLoadResult> obtenerCarteraHoy(List<String> asesorIds) async {
    final ids = asesorIds.where((id) => id.trim().isNotEmpty).toSet().toList();
    if (ids.isEmpty) {
      return CarteraLoadResult(items: [], desdeCache: false);
    }

    final hoy = DateTime.now().toIso8601String().split('T').first;

    if (_red.hayConexion) {
      final remoto = await _remoto.getCarteraHoyPorIds(ids);
      if (remoto.items.isNotEmpty) {
        final cacheId = remoto.items.first.asesorid;
        await _local.guardarCarteraCache(
          asesorid: cacheId,
          fecha: hoy,
          items: remoto.items.map((c) => _toMap(c)).toList(),
        );
        return CarteraLoadResult(
          items: remoto.items,
          desdeCache: false,
          aviso: remoto.aviso,
        );
      }
      final cache = await _leerPrimeraCache(ids, hoy);
      if (cache != null) return cache;
      return CarteraLoadResult(
        items: [],
        desdeCache: false,
        aviso: remoto.aviso,
      );
    }

    final cache = await _leerPrimeraCache(ids, hoy);
    return cache ??
        CarteraLoadResult(
          items: [],
          desdeCache: true,
        );
  }

  Future<CarteraLoadResult?> _leerPrimeraCache(
    List<String> ids,
    String fecha,
  ) async {
    final uuids = await _remoto.resolverUuidsAsesor(ids);
    final claves = {...uuids, ...ids};
    for (final id in claves) {
      final raw = await _local.leerCarteraCache(asesorid: id, fecha: fecha);
      if (raw.isEmpty) continue;
      final items = raw.map((j) => CarteraDiariaModel.fromJson(j)).toList();
      return CarteraLoadResult(
        items: CarteraPrioridadCalculator.conScore(items),
        desdeCache: true,
      );
    }
    return null;
  }

  Map<String, dynamic> _toMap(CarteraDiariaModel c) {
    return {
      'id': c.id,
      'asesorid': c.asesorid,
      'nombrecliente': c.nombrecliente,
      'documento': c.documento,
      'tipogestion': c.tipogestion,
      'monto': c.monto,
      'prioridad': c.prioridadServidor,
      'fechaasignacion': c.fechaasignacion,
      'estadovisita': c.estadovisita,
      'moraactiva': c.moraactiva,
      'diasenmora': c.diasenmora,
      'direccion': c.direccion,
      'telefono': c.telefono,
      'latitud': c.latitud,
      'longitud': c.longitud,
      'clienteid': c.clienteid,
    };
  }
}
