import 'package:flutter/material.dart';
import '../services/scoring_service.dart';
import '../model/scoring_resultado_model.dart';

class ScoringViewModel extends ChangeNotifier {
  final ScoringService _scoringService = ScoringService();
  ScoringResultadoModel? _resultado;
  bool _loading = false;
  String? _error;

  ScoringResultadoModel? get resultado => _resultado;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> evaluar({
    required String fichaid,
    required double monto,
    required int plazoMeses,
  }) async {
    _loading = true;
    _error = null;
    _resultado = null;
    notifyListeners();

    _resultado = await _scoringService.evaluarCreditoCampo(
      fichaid: fichaid,
      monto: monto,
      plazoMeses: plazoMeses,
    );

    if (_resultado == null) {
      _error = 'No se pudo evaluar el crédito';
    }

    _loading = false;
    notifyListeners();
  }
}
