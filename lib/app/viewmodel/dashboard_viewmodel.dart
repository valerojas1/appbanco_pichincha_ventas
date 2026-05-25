import 'package:flutter/material.dart';
import '../services/asesor_service.dart';
import '../model/dashboard_asesor_model.dart';

class DashboardViewModel extends ChangeNotifier {
  final AsesorService _asesorService = AsesorService();
  DashboardAsesorModel? _dashboard;
  bool _loading = false;

  DashboardAsesorModel? get dashboard => _dashboard;
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
    notifyListeners();
  }
}
