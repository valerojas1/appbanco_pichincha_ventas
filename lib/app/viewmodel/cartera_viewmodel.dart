import 'dart:async';
import 'package:flutter/material.dart';
import '../model/cartera_diaria_model.dart';
import '../repositories/cartera_repository.dart';
import '../services/cartera_orden_local_db.dart';
import '../services/visita_cartera_service.dart';
import '../services/ficha_cliente_service.dart';

enum CarteraFiltroLocal { todos, renovaciones, nuevas, enMora, visitados }

class CarteraViewModel extends ChangeNotifier {
  final CarteraRepository _carteraRepo = CarteraRepository();
  final CarteraOrdenLocalDb _ordenDb = CarteraOrdenLocalDb();
  final VisitaCarteraService _visitaService = VisitaCarteraService();
  final FichaClienteService _fichaClienteService = FichaClienteService();

  List<CarteraDiariaModel> _items = [];
  List<CarteraDiariaModel> _itemsVisibles = [];
  bool _loading = false;
  String? _asesorid;
  String _fechaHoy = '';
  CarteraFiltroLocal _filtro = CarteraFiltroLocal.todos;
  String _busqueda = '';
  Timer? _debounceBusqueda;

  List<CarteraDiariaModel> get itemsVisibles => _itemsVisibles;
  bool get loading => _loading;
  bool get desdeCache => _desdeCache;
  CarteraFiltroLocal get filtro => _filtro;
  List<String> _asesorIds = [];
  bool _desdeCache = false;
  String? _aviso;
  String? get aviso => _aviso;

  int get total => _items.length;
  int get visitados =>
      _items.where((i) => i.estadovisita == 'visitado').length;
  double get progresoVisitados => total == 0 ? 0 : visitados / total;

  Future<void> cargarCartera(List<String> asesorIds) async {
    _asesorIds = asesorIds;
    _asesorid = asesorIds.isNotEmpty ? asesorIds.first : null;
    _fechaHoy = DateTime.now().toIso8601String().split('T').first;
    _loading = true;
    notifyListeners();

    final resultado = await _carteraRepo.obtenerCarteraHoy(asesorIds);
    _items = resultado.items;
    _desdeCache = resultado.desdeCache;
    _aviso = resultado.aviso;
    if (!resultado.desdeCache && _items.isNotEmpty) {
      _asesorid = _items.first.asesorid;
      _fichaClienteService.sincronizarCarteraAsesor(_asesorid!);
    }
    await _aplicarOrdenGuardado();
    _aplicarFiltrosYBusqueda();

    _loading = false;
    notifyListeners();
  }

  Future<void> _aplicarOrdenGuardado() async {
    if (_asesorid == null) return;
    final ordenMap = await _ordenDb.cargarOrden(
      asesorid: _asesorid!,
      fecha: _fechaHoy,
    );
    if (ordenMap.isEmpty) {
      _ordenarPorPrioridad();
      return;
    }

    _items.sort((a, b) {
      final pa = ordenMap[a.id] ?? 9999;
      final pb = ordenMap[b.id] ?? 9999;
      return pa.compareTo(pb);
    });
  }

  void _ordenarPorPrioridad() {
    _items.sort((a, b) => b.scorePrioridad.compareTo(a.scorePrioridad));
  }

  void setFiltro(CarteraFiltroLocal filtro) {
    _filtro = filtro;
    _aplicarFiltrosYBusqueda();
    notifyListeners();
  }

  void setBusqueda(String texto) {
    _debounceBusqueda?.cancel();
    _debounceBusqueda = Timer(const Duration(milliseconds: 300), () {
      _busqueda = texto.trim().toLowerCase();
      _aplicarFiltrosYBusqueda();
      notifyListeners();
    });
  }

  void _aplicarFiltrosYBusqueda() {
    Iterable<CarteraDiariaModel> lista = _items;

    switch (_filtro) {
      case CarteraFiltroLocal.renovaciones:
        lista = lista.where((i) => i.tipogestion == 'RENOVACION');
        break;
      case CarteraFiltroLocal.nuevas:
        lista = lista.where((i) => i.tipogestion == 'NUEVA SOLICITUD');
        break;
      case CarteraFiltroLocal.enMora:
        lista = lista.where((i) => i.esMora);
        break;
      case CarteraFiltroLocal.visitados:
        lista = lista.where((i) => i.estadovisita == 'visitado');
        break;
      case CarteraFiltroLocal.todos:
        break;
    }

    if (_busqueda.isNotEmpty) {
      lista = lista.where((i) {
        final nombre = i.nombrecliente.toLowerCase();
        final ultimos4 = i.documento.replaceAll(RegExp(r'\D'), '');
        final doc4 = ultimos4.length >= 4
            ? ultimos4.substring(ultimos4.length - 4)
            : ultimos4;
        return nombre.contains(_busqueda) || doc4.contains(_busqueda);
      });
    }

    final filtrados = lista.toList();
    final pendientes =
        filtrados.where((i) => i.estadovisita != 'visitado').toList();
    final hechos =
        filtrados.where((i) => i.estadovisita == 'visitado').toList();

    _itemsVisibles = [...pendientes, ...hechos];
  }

  Future<void> reordenarPendientes(int oldIndex, int newIndex) async {
    if (_asesorid == null || oldIndex == newIndex) return;

    final pendientes =
        _items.where((i) => i.estadovisita != 'visitado').toList();
    if (oldIndex < 0 ||
        oldIndex >= pendientes.length ||
        newIndex < 0 ||
        newIndex > pendientes.length) {
      return;
    }

    if (newIndex > oldIndex) newIndex -= 1;
    final movido = pendientes.removeAt(oldIndex);
    pendientes.insert(newIndex, movido);

    final visitados =
        _items.where((i) => i.estadovisita == 'visitado').toList();
    _items = [...pendientes, ...visitados];

    await _ordenDb.guardarOrden(
      asesorid: _asesorid!,
      fecha: _fechaHoy,
      carteraIdsEnOrden: _items.map((e) => e.id).toList(),
    );

    _aplicarFiltrosYBusqueda();
    notifyListeners();
  }

  Future<bool> registrarResultadoVisita({
    required String carteraid,
    required String resultado,
    required String observacion,
    required double? latitud,
    required double? longitud,
  }) async {
    if (_asesorid == null) return false;

    final ok = await _visitaService.registrarVisita(
      carteraid: carteraid,
      asesorid: _asesorid!,
      resultado: resultado,
      observacion: observacion,
      latitud: latitud,
      longitud: longitud,
      registradoAt: DateTime.now(),
    );

    final index = _items.indexWhere((i) => i.id == carteraid);
    if (index != -1) {
      _items[index] = _items[index].copyWith(estadovisita: resultado);
    }

    _aplicarFiltrosYBusqueda();
    notifyListeners();
    return ok;
  }

  void actualizarCoordenadasLocal(
    String carteraid, {
    required double latitud,
    required double longitud,
    String? direccion,
  }) {
    final index = _items.indexWhere((i) => i.id == carteraid);
    if (index == -1) return;

    _items[index] = _items[index].copyWith(
      latitud: latitud,
      longitud: longitud,
      direccion: direccion,
    );
    _aplicarFiltrosYBusqueda();
    notifyListeners();
  }

  Future<void> sincronizarVisitasPendientes() async {
    await _visitaService.sincronizarPendientes();
    if (_asesorIds.isNotEmpty) await cargarCartera(_asesorIds);
  }

  @override
  void dispose() {
    _debounceBusqueda?.cancel();
    super.dispose();
  }
}
