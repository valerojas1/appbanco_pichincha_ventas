/// Mapas OpenStreetMap vía flutter_map (sin API key ni Google Cloud).
class MapsConfig {
  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static const String osmUserAgent = 'com.example.appbanco_pichincha_ventas';

  static const LatLngCentro centroHuancayo = LatLngCentro(
    latitud: -12.0664,
    longitud: -75.2137,
  );
}

class LatLngCentro {
  final double latitud;
  final double longitud;
  const LatLngCentro({required this.latitud, required this.longitud});
}
