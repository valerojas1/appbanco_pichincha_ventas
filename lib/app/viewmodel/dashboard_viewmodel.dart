import 'package:flutter/material.dart';
import '../services/asesor_service.dart';
import '../services/campana_activa_service.dart';
import '../model/dashboard_asesor_model.dart';
import '../model/campana_activa_model.dart';

class DashboardViewModel extends ChangeNotifier {
  final AsesorService _asesorService = AsesorService();
  final CampanaActivaService _campanaService = CampanaActivaService();
  DashboardAsesorModel? _dashboard;
  List<CampanaActivaModel> _campanas = [];
  bool _loading = false;

  DashboardAsesorModel? get dashboard => _dashboard;
  List<CampanaActivaModel> get campanas => _campanas;
  bool get loading => _loading;

  Future<void> cargarDashboard(String asesorid) async {
    _loading = true;
    notifyListeners();

    await recargar(asesorid);

    _loading = false;
    notifyListeners();
  }

  Future<void> recargar(String asesorid) async {
    _dashboard = await _asesorService.getDashboard(asesorid);
    _campanas = await _campanaService.listarVigentes(asesorid);
    notifyListeners();
  }
}
