import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/productividad_asesor_model.dart';

class ReporteProductividadService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<ProductividadAsesorModel>> cargarMesActual() async {
    final now = DateTime.now();
    final inicio = DateTime(now.year, now.month, 1).toIso8601String();

    try {
      final rows = await _client
          .from('solicitudescredito')
          .select('asesorid, estado, monto')
          .gte('createdat', inicio);

      final map = <String, _ProdAcum>{};
      for (final r in rows as List) {
        final row = Map<String, dynamic>.from(r as Map);
        final aid = row['asesorid']?.toString() ?? '';
        if (aid.isEmpty) continue;
        map.putIfAbsent(aid, () => _ProdAcum(aid));
        final a = map[aid]!;
        final estado = row['estado']?.toString() ?? '';
        final monto = (row['monto'] as num?)?.toDouble() ?? 0;

        if (estado == 'enviada' ||
            estado == 'en_comite' ||
            estado == 'aprobada' ||
            estado == 'desembolsada' ||
            estado == 'rechazada') {
          a.enviadas++;
        }
        if (estado == 'aprobada' || estado == 'desembolsada') {
          a.aprobadas++;
        }
        if (estado == 'desembolsada') {
          a.desembolsadas++;
          a.montoDesembolsado += monto;
        }
      }

      return map.values.map((a) {
        final tasa = a.enviadas == 0 ? 0.0 : (a.aprobadas / a.enviadas) * 100;
        return ProductividadAsesorModel(
          asesorid: a.asesorid,
          nombreAsesor: 'Asesor ${a.asesorid}',
          enviadas: a.enviadas,
          aprobadas: a.aprobadas,
          desembolsadas: a.desembolsadas,
          montoDesembolsado: a.montoDesembolsado,
          tasaAprobacion: tasa,
        );
      }).toList()
        ..sort((x, y) => y.desembolsadas.compareTo(x.desembolsadas));
    } catch (_) {
      return [];
    }
  }
}

class _ProdAcum {
  final String asesorid;
  int enviadas = 0;
  int aprobadas = 0;
  int desembolsadas = 0;
  double montoDesembolsado = 0;

  _ProdAcum(this.asesorid);
}
