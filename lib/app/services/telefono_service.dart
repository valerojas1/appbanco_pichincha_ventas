import 'package:url_launcher/url_launcher.dart';

class TelefonoService {
  Future<bool> llamar(String? telefono) async {
    if (telefono == null || telefono.trim().isEmpty) return false;
    final digits = telefono.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return false;
    final uri = Uri.parse('tel:$digits');
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri);
    }
    return false;
  }
}
