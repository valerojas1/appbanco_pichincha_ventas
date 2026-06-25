import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/cartera_tipo_gestion_style.dart';
import '../../model/cartera_diaria_model.dart';
import '../../core/asesor_id_util.dart';
import '../../core/network_service.dart';
import '../../viewmodel/auth_oficial_viewmodel.dart';
import '../../viewmodel/cartera_viewmodel.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/oficial_scaffold.dart';
import 'ficha_cliente_screen.dart';
import 'ficha_cartera_screen.dart';
import 'flujo_nueva_solicitud_screen.dart';

class CarteraDiariaScreen extends StatefulWidget {
  final bool embedded;

  const CarteraDiariaScreen({super.key, this.embedded = false});

  @override
  State<CarteraDiariaScreen> createState() => _CarteraDiariaScreenState();
}

class _CarteraDiariaScreenState extends State<CarteraDiariaScreen> {
  final _busquedaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _busquedaController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final oficial = context.read<AuthOficialViewModel>().oficial;
      if (oficial != null) {
        context
            .read<CarteraViewModel>()
            .cargarCartera(AsesorIdUtil.idsConsulta(oficial));
      }
    });
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  String _mensajeListaVacia(CarteraViewModel vm) {
    if (vm.aviso != null && vm.aviso!.isNotEmpty) return vm.aviso!;
    if (vm.desdeCache && vm.total == 0) {
      return 'Modo offline: no hay cartera guardada para hoy en este celular.\n\n'
          '1. Activa WiFi o datos\n'
          '2. Abre esta pantalla y espera a que cargue la lista\n'
          '3. Apaga la red y desliza hacia abajo para refrescar';
    }
    if (NetworkService.instance.modoOffline && vm.total == 0) {
      return 'Sin conexión y sin copia local de la cartera de hoy.\n'
          'Primero carga la lista con internet.';
    }
    return 'Sin cartera para este asesor. Si ya insertaste datos en Supabase, '
        'desliza hacia abajo para refrescar.';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CarteraViewModel>();

    return OficialScaffold(
      embedded: widget.embedded,
      title: 'Cartera del Día',
      body: vm.loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.amarillo),
            )
          : Column(
              children: [
                if (vm.aviso != null && vm.aviso!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      vm.aviso!,
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 11,
                      ),
                    ),
                  ),
                _BarraProgreso(
                  visitados: vm.visitados,
                  total: vm.total,
                  progreso: vm.progresoVisitados,
                ),
                _FiltrosChips(
                  filtroActual: vm.filtro,
                  onFiltro: vm.setFiltro,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    controller: _busquedaController,
                    onChanged: vm.setBusqueda,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre o últimos 4 del DNI',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _busquedaController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _busquedaController.clear();
                                vm.setBusqueda('');
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      final oficial =
                          context.read<AuthOficialViewModel>().oficial;
                      if (oficial != null) {
                        await vm.cargarCartera(
                          AsesorIdUtil.idsConsulta(oficial),
                        );
                      }
                    },
                    color: AppTheme.amarillo,
                    child: vm.itemsVisibles.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(
                                height: MediaQuery.sizeOf(context).height * 0.25,
                              ),
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    _mensajeListaVacia(vm),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : _ListaCartera(items: vm.itemsVisibles, vm: vm),
                  ),
                ),
              ],
            ),
    );
  }
}

class _BarraProgreso extends StatelessWidget {
  final int visitados;
  final int total;
  final double progreso;

  const _BarraProgreso({
    required this.visitados,
    required this.total,
    required this.progreso,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.amarillo.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progreso del día',
                style: TextStyle(
                  color: AppTheme.amarillo.withValues(alpha: 0.9),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                '$visitados / $total visitados',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progreso.clamp(0, 1),
              minHeight: 10,
              backgroundColor: Colors.grey.shade700,
              valueColor: const AlwaysStoppedAnimation(AppTheme.azulVisitado),
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltrosChips extends StatelessWidget {
  final CarteraFiltroLocal filtroActual;
  final ValueChanged<CarteraFiltroLocal> onFiltro;

  const _FiltrosChips({
    required this.filtroActual,
    required this.onFiltro,
  });

  @override
  Widget build(BuildContext context) {
    const filtros = [
      (CarteraFiltroLocal.todos, 'Todos'),
      (CarteraFiltroLocal.renovaciones, 'Renovaciones'),
      (CarteraFiltroLocal.nuevas, 'Nuevas'),
      (CarteraFiltroLocal.enMora, 'En mora'),
      (CarteraFiltroLocal.visitados, 'Visitados'),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filtros.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = filtros[i];
          final sel = filtroActual == f.$1;
          return FilterChip(
            label: Text(f.$2),
            selected: sel,
            onSelected: (_) => onFiltro(f.$1),
            selectedColor: AppTheme.amarillo.withValues(alpha: 0.25),
            checkmarkColor: AppTheme.amarillo,
            labelStyle: TextStyle(
              color: sel ? AppTheme.amarillo : Colors.white70,
              fontSize: 12,
              fontWeight: sel ? FontWeight.bold : FontWeight.normal,
            ),
            backgroundColor: AppTheme.superficie,
            side: BorderSide(
              color: sel
                  ? AppTheme.amarillo.withValues(alpha: 0.5)
                  : Colors.white24,
            ),
          );
        },
      ),
    );
  }
}

class _ListaCartera extends StatelessWidget {
  final List<CarteraDiariaModel> items;
  final CarteraViewModel vm;

  const _ListaCartera({required this.items, required this.vm});

  @override
  Widget build(BuildContext context) {
    final pendientes =
        items.where((i) => i.estadovisita != 'visitado').toList();
    final visitados =
        items.where((i) => i.estadovisita == 'visitado').toList();

    return RefreshIndicator(
      onRefresh: () async {
        final oficial = context.read<AuthOficialViewModel>().oficial;
        if (oficial != null) {
          await vm.sincronizarVisitasPendientes();
          await vm.cargarCartera(AsesorIdUtil.idsConsulta(oficial));
        }
      },
      color: AppTheme.amarillo,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (pendientes.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverReorderableList(
                itemCount: pendientes.length,
                onReorder: vm.reordenarPendientes,
                itemBuilder: (context, index) {
                  final item = pendientes[index];
                  return _TarjetaCartera(
                    key: ValueKey(item.id),
                    item: item,
                    index: index,
                    esVisitado: false,
                    mostrarArrastre: true,
                    onTap: () => _abrirFicha(context, item),
                    onFichaCampo: () => _abrirFichaCampo(context, item),
                    onProcesar: item.tipogestion == 'NUEVA SOLICITUD'
                        ? () => _abrirFlujoNuevaSolicitud(context, item)
                        : null,
                  );
                },
              ),
            ),
          if (visitados.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  'Visitados',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = visitados[index];
                  return _TarjetaCartera(
                    key: ValueKey('v_${item.id}'),
                    item: item,
                    index: index,
                    esVisitado: true,
                    mostrarArrastre: false,
                    onTap: () => _abrirFicha(context, item),
                    onFichaCampo: () => _abrirFichaCampo(context, item),
                    onProcesar: item.tipogestion == 'NUEVA SOLICITUD'
                        ? () => _abrirFlujoNuevaSolicitud(context, item)
                        : null,
                  );
                },
                childCount: visitados.length,
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  void _abrirFlujoNuevaSolicitud(BuildContext context, CarteraDiariaModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlujoNuevaSolicitudScreen(cartera: item),
      ),
    ).then((_) {
      if (!context.mounted) return;
      final oficial = context.read<AuthOficialViewModel>().oficial;
      if (oficial != null) {
        context
            .read<CarteraViewModel>()
            .cargarCartera(AsesorIdUtil.idsConsulta(oficial));
      }
    });
  }

  void _abrirFicha(BuildContext context, CarteraDiariaModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FichaClienteScreen(
          args: FichaClienteArgs.fromCartera(item),
        ),
      ),
    ).then((_) {
      if (!context.mounted) return;
      final oficial = context.read<AuthOficialViewModel>().oficial;
      if (oficial != null) {
        context
            .read<CarteraViewModel>()
            .cargarCartera(AsesorIdUtil.idsConsulta(oficial));
      }
    });
  }

  void _abrirFichaCampo(BuildContext context, CarteraDiariaModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FichaCarteraScreen(cartera: item),
      ),
    ).then((_) {
      if (!context.mounted) return;
      final oficial = context.read<AuthOficialViewModel>().oficial;
      if (oficial != null) {
        context
            .read<CarteraViewModel>()
            .cargarCartera(AsesorIdUtil.idsConsulta(oficial));
      }
    });
  }
}

class _TarjetaCartera extends StatelessWidget {
  final CarteraDiariaModel item;
  final int index;
  final bool esVisitado;
  final bool mostrarArrastre;
  final VoidCallback onTap;
  final VoidCallback onFichaCampo;
  final VoidCallback? onProcesar;

  const _TarjetaCartera({
    super.key,
    required this.item,
    required this.index,
    required this.esVisitado,
    required this.mostrarArrastre,
    required this.onTap,
    required this.onFichaCampo,
    this.onProcesar,
  });

  @override
  Widget build(BuildContext context) {
    final colorTipo = CarteraTipoGestionStyle.color(item.tipogestion);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: esVisitado ? Colors.grey.shade800 : AppTheme.superficie,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: esVisitado
              ? Colors.grey.shade600
              : colorTipo.withValues(alpha: 0.35),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (mostrarArrastre)
                  ReorderableDragStartListener(
                    index: index,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 8, top: 4),
                      child: Icon(Icons.drag_handle, color: Colors.white38),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.nombrecliente,
                              style: TextStyle(
                                color: esVisitado
                                    ? Colors.white60
                                    : Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.amarillo.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'P${item.scorePrioridad}',
                              style: const TextStyle(
                                color: AppTheme.amarillo,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Doc. ${item.documentoCensurado}',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _Badge(
                            texto: CarteraTipoGestionStyle.etiquetaCorta(
                              item.tipogestion,
                            ),
                            color: colorTipo,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'S/ ${item.monto.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (onProcesar != null) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: onProcesar,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.naranjaNuevo,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              textStyle: const TextStyle(fontSize: 11),
                            ),
                            child: const Text('PROCESAR SOLICITUD'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Ficha de campo (GPS)',
                  onPressed: onFichaCampo,
                  icon: Icon(
                    Icons.assignment_outlined,
                    size: 20,
                    color: esVisitado ? Colors.white38 : AppTheme.amarillo,
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String texto;
  final Color color;

  const _Badge({required this.texto, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
