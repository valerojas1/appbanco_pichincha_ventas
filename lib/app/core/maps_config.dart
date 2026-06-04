/// Reemplaza con tu API Key de Google Maps (Cloud Console).
/// Android: también en AndroidManifest.xml → com.google.android.geo.API_KEY
class MapsConfig {
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  static bool get tieneApiKey => googleMapsApiKey.isNotEmpty;

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
