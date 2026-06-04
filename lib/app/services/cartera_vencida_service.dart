import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/cartera_vencida_model.dart';

class CarteraVencidaService {
  final SupabaseClient _client = Supabase.instance.client;
  RealtimeChannel? _canal;
  List<String> _asesorIdsActivos = [];

  /// Busca por todos los ids del perfil (asesorid, código empleado, userid…).
  Future<List<CarteraVencidaModel>> listarPorAsesorIds(
    List<String> asesorIds,
  ) async {
    final ids = asesorIds.where((id) => id.trim().isNotEmpty).toSet().toList();
    if (ids.isEmpty) return [];

    try {
      final filtroOr = ids.map((id) => 'asesorid.eq.$id').join(',');

      final rows = await _client
          .from('carteravencida')
          .select()
          .or(filtroOr)
          .gt('diasmora', 0)
          .order('diasmora', ascending: false);

      return (rows as List)
          .map((r) => CarteraVencidaModel.fromJson(
                Map<String, dynamic>.from(r as Map),
              ))
          .toList();
    } catch (e) {
      debugPrint('Error listar carteravencida: $e');
      rethrow;
    }
  }

  Future<CarteraVencidaModel?> obtenerPorId(String id) async {
    try {
      final row = await _client
          .from('carteravencida')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (row == null) return null;
      return CarteraVencidaModel.fromJson(Map<String, dynamic>.from(row));
    } catch (_) {
      return null;
    }
  }

  Future<double?> aplicarPagoParcial({
    required String carteravencidaid,
    required double montoPago,
  }) async {
    final actual = await obtenerPorId(carteravencidaid);
    if (actual == null) return null;

    final nuevoSaldo = (actual.saldoVencido - montoPago).clamp(0.0, double.infinity);
    final ahora = DateTime.now().toIso8601String();

    await _client.from('carteravencida').update({
      'saldovencido': nuevoSaldo,
      'ultimaaccionat': ahora,
      'updatedat': ahora,
    }).eq('id', carteravencidaid);

    return nuevoSaldo;
  }

  Future<void> marcarUltimaAccion(String carteravencidaid) async {
    final ahora = DateTime.now().toIso8601String();
    await _client.from('carteravencida').update({
      'ultimaaccionat': ahora,
      'updatedat': ahora,
    }).eq('id', carteravencidaid);
  }

  void suscribirCambios({
    required List<String> asesorIds,
    required void Function() onCambio,
  }) {
    _asesorIdsActivos = asesorIds;
    _canal?.unsubscribe();
    final canalId = asesorIds.join('_');
    _canal = _client
        .channel('cartera_vencida_$canalId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'carteravencida',
          callback: (payload) {
            final record = payload.newRecord.isNotEmpty
                ? payload.newRecord
                : payload.oldRecord;
            final aid = record['asesorid']?.toString();
            if (aid == null || !_asesorIdsActivos.contains(aid)) return;
            onCambio();
          },
        )
        .subscribe();
  }

  void cancelarSuscripcion() {
    _canal?.unsubscribe();
    _canal = null;
  }
}
