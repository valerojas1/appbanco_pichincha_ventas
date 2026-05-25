import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/meta_asesor_model.dart';

class MetasViewModel extends ChangeNotifier {
  MetaAsesorModel? _metas;
  bool _loading = false;

  MetaAsesorModel? get metas => _metas;
  bool get loading => _loading;

  Future<void> cargarMetas(String asesorid) async {
    _loading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final response = await Supabase.instance.client
          .from('metasasesores')
          .select()
          .eq('asesorid', asesorid)
          .eq('anio', now.year)
          .eq('mes', now.month)
          .maybeSingle();
      if (response != null) {
        _metas = MetaAsesorModel.fromJson(response);
      }
    } catch (_) {}

    _loading = false;
    notifyListeners();
  }
}
