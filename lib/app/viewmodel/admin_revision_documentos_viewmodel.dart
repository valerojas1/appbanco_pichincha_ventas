import 'package:flutter/material.dart';
import '../model/documento_slot_model.dart';
import '../services/admin_web_service.dart';
import '../services/solicitud_documento_service.dart';

class AdminRevisionDocumentosViewModel extends ChangeNotifier {
  final AdminWebService _adminService = AdminWebService();
  final SolicitudDocumentoService _docService = SolicitudDocumentoService();

  List<AdminSolicitudDocsResumen> _lista = [];
  Map<String, DocumentoSlotModel> _slots = {};
  bool _cargandoLista = false;
  bool _cargandoDetalle = false;
  String? _solicitudSeleccionada;

  List<AdminSolicitudDocsResumen> get lista => _lista;
  Map<String, DocumentoSlotModel> get slots => _slots;
  bool get cargandoLista => _cargandoLista;
  bool get cargandoDetalle => _cargandoDetalle;
  String? get solicitudSeleccionada => _solicitudSeleccionada;

  Future<void> cargarLista() async {
    _cargandoLista = true;
    notifyListeners();

    _lista = await _adminService.listarSolicitudesConDocumentos();

    _cargandoLista = false;
    notifyListeners();
  }

  Future<void> cargarDocumentos(String solicitudId) async {
    _solicitudSeleccionada = solicitudId;
    _cargandoDetalle = true;
    notifyListeners();

    _slots = await _docService.cargarSlots(solicitudId);

    _cargandoDetalle = false;
    notifyListeners();
  }

  void limpiarDetalle() {
    _solicitudSeleccionada = null;
    _slots = {};
    notifyListeners();
  }
}
