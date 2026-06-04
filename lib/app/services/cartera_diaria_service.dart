import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/cartera_prioridad_calculator.dart';
import '../model/cartera_diaria_model.dart';

/// Resultado de consulta remota con aviso opcional (p. ej. desfase de fecha).
class CarteraRemotaResult {
  final List<CarteraDiariaModel> items;
  final String? aviso;

  CarteraRemotaResult({required this.items, this.aviso});
}

class CarteraDiariaService {
  final SupabaseClient _client = Supabase.instance.client;

  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  static bool esUuid(String value) => _uuidRegex.hasMatch(value.trim());

  static String fechaLocalHoy() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  static String _soloFecha(String raw) {
    final t = raw.trim();
    if (t.length >= 10) return t.substring(0, 10);
    return t;
  }

  static bool esFechaHoy(String fechaasignacion) =>
      _soloFecha(fechaasignacion) == fechaLocalHoy();

  Future<List<String>> resolverUuidsAsesor(List<String> candidatos) async {
    final uuids = <String>{};

    for (final id in candidatos) {
      final t = id.trim();
      if (t.isEmpty) continue;
      if (esUuid(t)) uuids.add(t);
    }

    if (uuids.isNotEmpty) return uuids.toList();

    for (final codigo in candidatos) {
      final t = codigo.trim();
      if (t.isEmpty || esUuid(t)) continue;
      final uuid = await _uuidDesdeVwPerfil(codigoEmpleado: t);
      if (uuid != null) uuids.add(uuid);
    }

    return uuids.toList();
  }

  Future<String?> _uuidDesdeVwPerfil({required String codigoEmpleado}) async {
    try {
      final row = await _client
          .from('vwperfilasesor')
          .select('asesorid')
          .eq('codigoempleado', codigoEmpleado)
          .maybeSingle();
      final id = row?['asesorid']?.toString();
      if (id != null && esUuid(id)) return id;
    } catch (e) {
      debugPrint('No se pudo resolver UUID para código $codigoEmpleado: $e');
    }
    return null;
  }

  Future<List<CarteraDiariaModel>> getCarteraHoy(String asesorid) async {
    final r = await getCarteraHoyPorIds([asesorid]);
    return r.items;
  }

  Future<CarteraRemotaResult> getCarteraHoyPorIds(
    List<String> candidatos,
  ) async {
    final uuids = await resolverUuidsAsesor(candidatos);
    final hoy = fechaLocalHoy();

    if (uuids.isEmpty) {
      return CarteraRemotaResult(
        items: [],
        aviso:
            'No se encontró el UUID del asesor. Cierra sesión, vuelve a entrar '
            'con 100001 y refresca.',
      );
    }

    for (final uuid in uuids) {
      try {
        final response = await _client
            .from('carteradiaria')
            .select()
            .eq('asesorid', uuid)
            .order('fechaasignacion', ascending: false);

        final todas = (response as List)
            .map((e) => CarteraDiariaModel.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ))
            .toList();

        if (todas.isEmpty) continue;

        final hoyLista =
            todas.where((c) => esFechaHoy(c.fechaasignacion)).toList();
        if (hoyLista.isNotEmpty) {
          return CarteraRemotaResult(
            items: CarteraPrioridadCalculator.conScore(hoyLista),
          );
        }

        final fechaDb = _soloFecha(todas.first.fechaasignacion);
        final delDia = todas
            .where((c) => _soloFecha(c.fechaasignacion) == fechaDb)
            .toList();

        return CarteraRemotaResult(
          items: CarteraPrioridadCalculator.conScore(delDia),
          aviso:
              'Hay cartera en Supabase para el $fechaDb, pero tu celular busca '
              'el $hoy. Ajusta la fecha del dispositivo o vuelve a ejecutar el '
              'INSERT con la fecha de hoy en el SQL Editor.',
        );
      } catch (e) {
        debugPrint('Error carteradiaria asesor $uuid: $e');
        return CarteraRemotaResult(
          items: [],
          aviso: 'Error al leer carteradiaria: $e',
        );
      }
    }

    return CarteraRemotaResult(items: []);
  }

  Future<bool> actualizarCoordenadas({
    required String carteraid,
    required double latitud,
    required double longitud,
    String? direccion,
  }) async {
    try {
      final data = <String, dynamic>{
        'latitud': latitud,
        'longitud': longitud,
        'updatedat': DateTime.now().toIso8601String(),
      };
      if (direccion != null) data['direccion'] = direccion;
      await _client.from('carteradiaria').update(data).eq('id', carteraid);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> actualizarEstadoVisita(String carteraid, String estado) async {
    try {
      await _client.from('carteradiaria').update({
        'estadovisita': estado,
        'updatedat': DateTime.now().toIso8601String(),
      }).eq('id', carteraid);
      return true;
    } catch (_) {
      return false;
    }
  }
}
