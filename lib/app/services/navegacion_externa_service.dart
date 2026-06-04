import 'package:url_launcher/url_launcher.dart';

class NavegacionExternaService {
  Future<bool> abrirNavegacion({
    required double latitud,
    required double longitud,
    String? etiqueta,
  }) async {
    final nombre = Uri.encodeComponent(etiqueta ?? 'Destino');

    final waze = Uri.parse(
      'waze://?ll=$latitud,$longitud&navigate=yes',
    );
    if (await canLaunchUrl(waze)) {
      return launchUrl(waze, mode: LaunchMode.externalApplication);
    }

    final googleMapsApp = Uri.parse(
      'google.navigation:q=$latitud,$longitud',
    );
    if (await canLaunchUrl(googleMapsApp)) {
      return launchUrl(googleMapsApp, mode: LaunchMode.externalApplication);
    }

    final mapsWeb = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitud,$longitud&destination_place_id=$nombre',
    );
    if (await canLaunchUrl(mapsWeb)) {
      return launchUrl(mapsWeb, mode: LaunchMode.externalApplication);
    }

    return false;
  }
}
