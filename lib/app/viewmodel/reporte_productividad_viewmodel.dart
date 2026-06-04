import 'package:flutter/material.dart';
import '../model/productividad_asesor_model.dart';
import '../services/reporte_productividad_pdf_service.dart';
import '../services/reporte_productividad_service.dart';

class ReporteProductividadViewModel extends ChangeNotifier {
  final ReporteProductividadService _service = ReporteProductividadService();
  final ReporteProductividadPdfService _pdf = ReporteProductividadPdfService();

  List<ProductividadAsesorModel> _filas = [];
  bool _cargando = false;
  bool _exportando = false;
  String? _error;

  List<ProductividadAsesorModel> get filas => _filas;
  bool get cargando => _cargando;
  bool get exportando => _exportando;
  String? get error => _error;

  Future<void> cargar() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    _filas = await _service.cargarMesActual();
    _cargando = false;
    notifyListeners();
  }

  Future<void> exportarPdf() async {
    if (_filas.isEmpty) return;
    _exportando = true;
    notifyListeners();
    try {
      final bytes = await _pdf.generar(_filas);
      await _pdf.compartir(bytes);
    } catch (e) {
      _error = 'No se pudo exportar PDF: $e';
    }
    _exportando = false;
    notifyListeners();
  }
}
