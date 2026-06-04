import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/transmision_paso.dart';

/// Persiste el progreso de transmisión para reanudación atómica.
class TransmisionEstadoLocalService {
  static const _prefix = 'transmision_';

  Future<Map<String, dynamic>?> leer(String solicitudId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$solicitudId');
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  Future<void> guardarPasoCompletado({
    required String solicitudId,
    required TransmisionPaso paso,
    String? numeroExpediente,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final actual = await leer(solicitudId) ?? {};
    actual['ultimo_paso'] = paso.indice;
    actual['updatedat'] = DateTime.now().toIso8601String();
    if (numeroExpediente != null) {
      actual['numero_expediente'] = numeroExpediente;
    }
    await prefs.setString(
      '$_prefix$solicitudId',
      jsonEncode(actual),
    );
  }

  Future<int> ultimoPasoCompletado(String solicitudId) async {
    final data = await leer(solicitudId);
    if (data == null) return -1;
    return data['ultimo_paso'] is int
        ? data['ultimo_paso'] as int
        : int.tryParse(data['ultimo_paso']?.toString() ?? '') ?? -1;
  }

  Future<void> limpiar(String solicitudId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$solicitudId');
  }
}
