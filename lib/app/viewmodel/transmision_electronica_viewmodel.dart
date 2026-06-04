import 'package:flutter/material.dart';
import '../model/transmision_paso.dart';
import '../services/transmision_electronica_service.dart';

class TransmisionElectronicaViewModel extends ChangeNotifier {
  final TransmisionElectronicaService _service = TransmisionElectronicaService();

  String? _solicitudId;
  String _titulo = '';
  TransmisionPaso _pasoActual = TransmisionPaso.validando;
  bool _ejecutando = false;
  bool _completado = false;
  List<String> _erroresValidacion = [];
  String? _numeroExpediente;
  String? _error;

  String? get solicitudId => _solicitudId;
  String get titulo => _titulo;
  TransmisionPaso get pasoActual => _pasoActual;
  bool get ejecutando => _ejecutando;
  bool get completado => _completado;
  List<String> get erroresValidacion => _erroresValidacion;
  String? get numeroExpediente => _numeroExpediente;
  String? get error => _error;

  Future<void> iniciar({
    required String solicitudId,
    required String tituloSolicitud,
  }) async {
    _solicitudId = solicitudId;
    _titulo = tituloSolicitud;
    _completado = false;
    _erroresValidacion = [];
    _error = null;
    _numeroExpediente = null;

    final reanudar = await _service.pasoParaReanudar(solicitudId);
    _pasoActual =
        TransmisionPaso.fromIndice(reanudar) ?? TransmisionPaso.validando;
    notifyListeners();
  }

  Future<void> ejecutarTransmisionCompleta() async {
    if (_solicitudId == null) return;

    _ejecutando = true;
    _error = null;
    _erroresValidacion = [];
    notifyListeners();

    var paso = _pasoActual;
    while (paso.indice <= TransmisionPaso.enviado.indice) {
      _pasoActual = paso;
      notifyListeners();

      if (paso == TransmisionPaso.enviado) {
        await _service.marcarPasoOk(
          solicitudId: _solicitudId!,
          paso: TransmisionPaso.enviado,
        );
        _completado = true;
        break;
      }

      final errores = await _service.ejecutarPaso(
        solicitudId: _solicitudId!,
        paso: paso,
      );

      if (errores.isNotEmpty) {
        if (paso == TransmisionPaso.validando) {
          _erroresValidacion = errores;
        }
        _error = errores.first;
        _ejecutando = false;
        notifyListeners();
        return;
      }

      await _service.marcarPasoOk(
        solicitudId: _solicitudId!,
        paso: paso,
      );

      if (paso == TransmisionPaso.asignandoExpediente) {
        _numeroExpediente =
            await _service.obtenerNumeroExpediente(_solicitudId!);
      }

      final next = paso.siguiente;
      if (next == null) break;
      paso = next;
    }

    if (_completado) {
      await _service.limpiarProgresoLocal(_solicitudId!);
    }

    _ejecutando = false;
    notifyListeners();
  }

}
