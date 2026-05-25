import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/dashboard_asesor_model.dart';

class AsesorService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<DashboardAsesorModel?> getDashboard(String asesorid) async {
    try {
      final response = await _client
          .from('vwdashboardasesor')
          .select()
          .eq('asesorid', asesorid)
          .maybeSingle();
      if (response == null) return null;
      return DashboardAsesorModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }
}
