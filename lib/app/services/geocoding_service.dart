import 'package:geocoding/geocoding.dart';

class GeocodingService {
  Future<String?> direccionDesdeCoordenadas(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return null;
      final p = placemarks.first;
      final partes = [
        p.street,
        p.subLocality,
        p.locality,
        p.administrativeArea,
      ].where((e) => e != null && e!.trim().isNotEmpty).map((e) => e!.trim());
      return partes.join(', ');
    } catch (_) {
      return null;
    }
  }
}
