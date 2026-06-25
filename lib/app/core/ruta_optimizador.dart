import 'package:latlong2/latlong.dart';

class RutaOptimizador {
  /// Vecino más cercano desde [origen] sobre clientes con coordenadas.
  static List<String> ordenarVecinoMasCercano({
    required LatLng origen,
    required Map<String, LatLng> clientesPorId,
    List<String>? idsIniciales,
  }) {
    final ids = (idsIniciales ?? clientesPorId.keys.toList())
        .where((id) => clientesPorId.containsKey(id))
        .toList();
    if (ids.isEmpty) return [];

    final pendientes = List<String>.from(ids);
    final orden = <String>[];
    var actual = origen;

    while (pendientes.isNotEmpty) {
      String? masCercano;
      var distMin = double.infinity;

      for (final id in pendientes) {
        final dest = clientesPorId[id]!;
        final d = _distancia(actual, dest);
        if (d < distMin) {
          distMin = d;
          masCercano = id;
        }
      }

      if (masCercano == null) break;
      pendientes.remove(masCercano);
      orden.add(masCercano);
      actual = clientesPorId[masCercano]!;
    }

    return orden;
  }

  static List<LatLng> puntosPolilinea({
    required LatLng origen,
    required List<String> ordenIds,
    required Map<String, LatLng> clientesPorId,
  }) {
    final puntos = <LatLng>[origen];
    for (final id in ordenIds) {
      final p = clientesPorId[id];
      if (p != null) puntos.add(p);
    }
    return puntos;
  }

  static double _distancia(LatLng a, LatLng b) {
    final dlat = a.latitude - b.latitude;
    final dlng = a.longitude - b.longitude;
    return dlat * dlat + dlng * dlng;
  }
}
