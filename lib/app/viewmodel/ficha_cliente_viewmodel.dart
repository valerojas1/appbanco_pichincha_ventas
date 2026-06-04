import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/alerta_cartera_model.dart';
import '../model/cliente_ficha_model.dart';
import '../model/credito_historial_model.dart';
import '../model/oferta_preaprobada_model.dart';
import '../model/pago_mensual_model.dart';
import '../model/posicion_cliente_model.dart';
import '../services/ficha_cliente_service.dart';
import '../services/telefono_service.dart';

class FichaClienteViewModel extends ChangeNotifier {
  final FichaClienteService _service = FichaClienteService();
  final TelefonoService _telefonoService = TelefonoService();

  ClienteFichaModel? _cliente;
  PosicionClienteModel? _posicion;
  List<CreditoHistorialModel> _creditos = [];
  List<PagoMensualModel> _pagos = [];
  OfertaPreaprobadaModel? _oferta;
  List<AlertaCarteraModel> _alertas = [];
  bool _loading = false;
  bool _offline = false;
  String? _error;
  RealtimeChannel? _canalAlertas;

  ClienteFichaModel? get cliente => _cliente;
  PosicionClienteModel? get posicion => _posicion;
  List<CreditoHistorialModel> get creditos => _creditos;
  List<PagoMensualModel> get pagos => _pagos;
  OfertaPreaprobadaModel? get oferta => _oferta;
  List<AlertaCarteraModel> get alertasCliente => _alertas
      .where((a) => a.clienteid == null || a.clienteid == _cliente?.id)
      .toList();
  bool get loading => _loading;
  bool get offline => _offline;
  String? get error => _error;

  double get porcentajePuntual {
    final conCuota = _pagos.where((p) => !p.esSinCuota).length;
    if (conCuota == 0) return 0;
    final puntual = _pagos.where((p) => p.esPuntual).length;
    return (puntual / conCuota) * 100;
  }

  double get diasPromedioMora {
    final moras = _pagos.where((p) => p.esMora).toList();
    if (moras.isEmpty) return 0;
    return moras.map((p) => p.diasmora).reduce((a, b) => a + b) / moras.length;
  }

  double get montoTotalPagado =>
      _pagos.fold(0.0, (s, p) => s + p.montopagado);

  Future<void> cargar({
    required String asesorid,
    String? clienteid,
    required String documento,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    _offline = !(await _service.hayConexion);
    final bundle = await _service.cargarBundle(
      clienteid: clienteid,
      documento: documento,
      asesorid: asesorid,
    );

    if (bundle == null) {
      _error = _offline
          ? 'Sin datos offline. Sincronice cuando tenga conexión.'
          : 'No se encontró el cliente';
      _loading = false;
      notifyListeners();
      return;
    }

    _parseBundle(bundle);
    _alertas = await _service.alertasPorAsesor(asesorid);
    _loading = false;
    notifyListeners();
  }

  void _parseBundle(Map<String, dynamic> bundle) {
    final cRaw = bundle['cliente'];
    if (cRaw is Map) {
      _cliente = ClienteFichaModel.fromJson(Map<String, dynamic>.from(cRaw));
    }
    final pos = bundle['posicion'];
    if (pos is Map) {
      _posicion = PosicionClienteModel.fromEdgeJson(
        Map<String, dynamic>.from(pos),
        desdeCache: _offline,
      );
    } else if (_cliente != null) {
      _posicion = PosicionClienteModel.fromCliente(_cliente!);
    }
    _creditos = [];
    final cr = bundle['creditos'];
    if (cr is List) {
      _creditos = cr
          .map((e) => CreditoHistorialModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();
    }
    _pagos = [];
    final pg = bundle['pagos'];
    if (pg is List) {
      _pagos = pg
          .map((e) => PagoMensualModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();
    }
    final of = bundle['oferta'];
    _oferta = of is Map
        ? OfertaPreaprobadaModel.fromJson(Map<String, dynamic>.from(of))
        : null;
  }

  void iniciarRealtime(String asesorid) {
    _canalAlertas?.unsubscribe();
    _canalAlertas = _service.suscribirAlertas(
      asesorid: asesorid,
      onNueva: (alerta) {
        if (_alertas.any((a) => a.id == alerta.id)) return;
        _alertas.insert(0, alerta);
        notifyListeners();
      },
    );
  }

  Future<bool> llamarCliente() async {
    return _telefonoService.llamar(_cliente?.telefono);
  }

  Future<int> sincronizarNocturna(String asesorid) =>
      _service.sincronizarCarteraAsesor(asesorid);

  @override
  void dispose() {
    _canalAlertas?.unsubscribe();
    super.dispose();
  }
}
