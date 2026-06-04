import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../model/geocerca_zona_model.dart';

class GeocercaUtil {
  static bool puntoDentroDePoligono(LatLng punto, List<LatLng> poligono) {
    if (poligono.length < 3) return false;

    var dentro = false;
    var j = poligono.length - 1;

    for (var i = 0; i < poligono.length; i++) {
      final xi = poligono[i].longitude;
      final yi = poligono[i].latitude;
      final xj = poligono[j].longitude;
      final yj = poligono[j].latitude;

      final intersecta = ((yi > punto.latitude) != (yj > punto.latitude)) &&
          (punto.longitude <
              (xj - xi) * (punto.latitude - yi) / (yj - yi + 0.0) + xi);
      if (intersecta) dentro = !dentro;
      j = i;
    }

    return dentro;
  }

  static bool estaDentroDeAlgunaZona(LatLng punto, List<GeocercaZonaModel> zonas) {
    for (final zona in zonas) {
      if (zona.activa && puntoDentroDePoligono(punto, zona.puntos)) {
        return true;
      }
    }
    return false;
  }

  static String? nombreZonaContenedora(
    LatLng punto,
    List<GeocercaZonaModel> zonas,
  ) {
    for (final zona in zonas) {
      if (zona.activa && puntoDentroDePoligono(punto, zona.puntos)) {
        return zona.nombre;
      }
    }
    return null;
  }
}
