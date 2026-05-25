import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/scoring_resultado_model.dart';

class ScoringService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<ScoringResultadoModel?> evaluarCreditoCampo({
    required String fichaid,
    required double monto,
    required int plazoMeses,
  }) async {
    try {
      final response = await _client.rpc('evaluarcreditocampo', params: {
        'pfichaid': fichaid,
        'pmonto': monto,
        'pplazomeses': plazoMeses,
      });
      return ScoringResultadoModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }
}
