import 'package:flutter/material.dart';
import '../services/scoring_service.dart';
import '../model/scoring_resultado_model.dart';

class ScoringPrefill {
  final String fichaid;
  final double monto;
  final int plazoMeses;

  const ScoringPrefill({
    required this.fichaid,
    required this.monto,
    required this.plazoMeses,
  });
}

class ScoringViewModel extends ChangeNotifier {
  final ScoringService _scoringService = ScoringService();
  ScoringResultadoModel? _resultado;
  bool _loading = false;
  String? _error;
  ScoringPrefill? _prefill;

  ScoringResultadoModel? get resultado => _resultado;
  bool get loading => _loading;
  String? get error => _error;
  ScoringPrefill? get prefill => _prefill;

  void aplicarOfertaPreaprobada({
    required String fichaid,
    required double monto,
    required int plazoMeses,
  }) {
    _prefill = ScoringPrefill(
      fichaid: fichaid,
      monto: monto,
      plazoMeses: plazoMeses,
    );
    notifyListeners();
  }

  void limpiarPrefill() {
    _prefill = null;
    notifyListeners();
  }

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
