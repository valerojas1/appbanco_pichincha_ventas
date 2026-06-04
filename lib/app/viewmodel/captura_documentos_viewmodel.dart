import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/documento_imagen_util.dart';
import '../model/documento_slot_model.dart';
import '../model/tipo_documento_config.dart';
import '../services/solicitud_documento_service.dart';

class CapturaDocumentosViewModel extends ChangeNotifier {
  final SolicitudDocumentoService _service = SolicitudDocumentoService();
  final ImagePicker _picker = ImagePicker();

  String? _solicitudId;
  String _tituloSolicitud = '';
  Map<String, DocumentoSlotModel> _slots = {};
  bool _cargando = false;
  bool _enviando = false;
  bool _procesandoImagen = false;
  String _etapaProceso = '';
  String? _error;
  String? _mensajeExito;

  Map<String, DocumentoSlotModel> get slots => _slots;
  bool get cargando => _cargando;
  bool get enviando => _enviando;
  bool get procesandoImagen => _procesandoImagen;
  String get etapaProceso => _etapaProceso;
  String? get error => _error;
  String? get mensajeExito => _mensajeExito;
  String? get solicitudId => _solicitudId;
  String get tituloSolicitud => _tituloSolicitud;

  bool get puedeEnviarSolicitud {
    for (final t in TipoDocumentoConfig.catalogo) {
      if (t.obligatorio && !(_slots[t.id]?.estaListo ?? false)) {
        return false;
      }
    }
    return _solicitudId != null;
  }

  int get obligatoriosListos {
    return TipoDocumentoConfig.catalogo
        .where((t) => t.obligatorio && (_slots[t.id]?.estaListo ?? false))
        .length;
  }

  int get totalObligatorios =>
      TipoDocumentoConfig.catalogo.where((t) => t.obligatorio).length;

  Future<void> iniciar({
    required String solicitudId,
    required String tituloSolicitud,
  }) async {
    _solicitudId = solicitudId;
    _tituloSolicitud = tituloSolicitud;
    _cargando = true;
    _error = null;
    notifyListeners();

    _slots = await _service.cargarSlots(solicitudId);
    _cargando = false;
    notifyListeners();
  }

  Future<String?> capturarDesdeCamara(String tipoId) async {
    return _procesarCaptura(tipoId, ImageSource.camera);
  }

  Future<String?> capturarDesdeGaleria(String tipoId) async {
    return _procesarCaptura(tipoId, ImageSource.gallery);
  }

  void _setEtapa(String etapa) {
    _etapaProceso = etapa;
    notifyListeners();
  }

  Future<String?> _procesarCaptura(String tipoId, ImageSource source) async {
    if (_solicitudId == null) return 'Solicitud no definida';
    final config = TipoDocumentoConfig.porId(tipoId);
    if (config == null) return 'Tipo de documento inválido';

    if (_procesandoImagen) return 'Espere a que termine el proceso anterior';

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (picked == null) return null;

    _procesandoImagen = true;
    _error = null;
    _setEtapa('Leyendo fotografía...');

    Uint8List raw;
    try {
      raw = await picked.readAsBytes();
    } catch (e) {
      _procesandoImagen = false;
      _etapaProceso = '';
      notifyListeners();
      return 'No se pudo leer la imagen: $e';
    }

    await Future<void>.delayed(Duration.zero);
    _setEtapa('Validando nitidez y optimizando imagen...');

    ResultadoProcesoImagen resultado;
    try {
      resultado = await DocumentoImagenUtil.procesarEnSegundoPlano(raw);
    } catch (e) {
      _procesandoImagen = false;
      _etapaProceso = '';
      notifyListeners();
      return 'Error al procesar la imagen: $e';
    }

    if (!resultado.nitida) {
      _procesandoImagen = false;
      _etapaProceso = '';
      notifyListeners();
      return 'Imagen poco nítida (puntaje ${resultado.nitidez.toStringAsFixed(0)}, '
          'mínimo ${DocumentoImagenUtil.nitidezMinima.toStringAsFixed(0)}). '
          'Retome la foto con mejor enfoque, luz y sin mover el celular.';
    }

    _slots[tipoId] = (_slots[tipoId] ?? DocumentoSlotModel(config: config))
        .copyWith(subiendo: true);
    _setEtapa('Subiendo documento al servidor...');

    try {
      final actualizado = await _service.subirDocumento(
        solicitudId: _solicitudId!,
        tipo: config,
        bytesJpeg: resultado.bytesJpeg,
        puntajeNitidez: resultado.nitidez,
      );
      _slots[tipoId] = actualizado;
      return null;
    } catch (e) {
      _slots[tipoId] = (_slots[tipoId] ?? DocumentoSlotModel(config: config))
          .copyWith(subiendo: false);
      return 'Error al subir: $e';
    } finally {
      _procesandoImagen = false;
      _etapaProceso = '';
      notifyListeners();
    }
  }

  Future<String?> eliminarDocumento(String tipoId) async {
    if (_solicitudId == null) return 'Solicitud no definida';
    final slot = _slots[tipoId];
    if (slot == null || !slot.estaListo) return null;

    try {
      await _service.eliminarDocumento(
        solicitudId: _solicitudId!,
        slot: slot,
      );
      _slots[tipoId] = DocumentoSlotModel(config: slot.config);
      notifyListeners();
      return null;
    } catch (e) {
      return 'No se pudo eliminar: $e';
    }
  }

  Future<bool> prepararTransmisionElectronica() async {
    if (!puedeEnviarSolicitud || _solicitudId == null) {
      _error = 'Complete todos los documentos obligatorios';
      notifyListeners();
      return false;
    }

    _enviando = true;
    _error = null;
    notifyListeners();

    try {
      await _service.marcarListaParaTransmitir(_solicitudId!);
      _enviando = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al preparar transmisión: $e';
      _enviando = false;
      notifyListeners();
      return false;
    }
  }
}
