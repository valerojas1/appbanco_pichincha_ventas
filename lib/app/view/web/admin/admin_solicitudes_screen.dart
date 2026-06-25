import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../model/estado_solicitud.dart';
import '../../../model/solicitud_resumen_model.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../viewmodel/admin_revision_documentos_viewmodel.dart';
import '../../../viewmodel/admin_solicitudes_tablero_viewmodel.dart';
import 'admin_solicitud_evaluacion_screen.dart';
import '../../home/visor_documento_screen.dart';
import 'admin_detalle_documentos_panel.dart';
import 'widgets/admin_content_header.dart';

class AdminSolicitudesScreen extends StatefulWidget {
  const AdminSolicitudesScreen({super.key});

  @override
  State<AdminSolicitudesScreen> createState() => _AdminSolicitudesScreenState();
}

class _AdminSolicitudesScreenState extends State<AdminSolicitudesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminSolicitudesTableroViewModel>().iniciar();
      context.read<AdminRevisionDocumentosViewModel>().cargarLista();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AdminContentHeader(
          titulo: 'Solicitudes',
          subtitulo:
              'Tablero de expedientes y revisión de documentación adjuntada por operadores',
        ),
        TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.amarillo,
          labelColor: AppTheme.amarillo,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Estado de solicitudes'),
            Tab(text: 'Revisión de documentos'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _TableroSolicitudesAdmin(),
              _RevisionDocumentosAdmin(),
            ],
          ),
        ),
      ],
    );
  }
}

class _TableroSolicitudesAdmin extends StatefulWidget {
  const _TableroSolicitudesAdmin();

  @override
  State<_TableroSolicitudesAdmin> createState() =>
      _TableroSolicitudesAdminState();
}

class _TableroSolicitudesAdminState extends State<_TableroSolicitudesAdmin>
    with SingleTickerProviderStateMixin {
  late TabController _estadoTab;

  @override
  void initState() {
    super.initState();
    _estadoTab = TabController(
      length: TabSolicitud.values.length,
      vsync: this,
    );
    _estadoTab.addListener(() {
      if (!_estadoTab.indexIsChanging) {
        context.read<AdminSolicitudesTableroViewModel>().cambiarTab(
              TabSolicitud.values[_estadoTab.index],
            );
      }
    });
  }

  @override
  void dispose() {
    _estadoTab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminSolicitudesTableroViewModel>();

    return Column(
      children: [
        TabBar(
          controller: _estadoTab,
          isScrollable: true,
          indicatorColor: AppTheme.amarillo,
          labelColor: AppTheme.amarillo,
          unselectedLabelColor: Colors.white54,
          tabs: TabSolicitud.values.map((t) {
            final n = vm.contadores[t] ?? 0;
            return Tab(text: '${t.titulo} ($n)');
          }).toList(),
        ),
        Expanded(
          child: vm.cargando
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.amarillo),
                )
              : vm.lista.isEmpty
                  ? const Center(
                      child: Text(
                        'Sin solicitudes en este estado',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: vm.refrescar,
                      color: AppTheme.amarillo,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: vm.lista.length,
                        itemBuilder: (_, i) =>
                            _TarjetaSolicitud(s: vm.lista[i]),
                      ),
                    ),
        ),
      ],
    );
  }
}

class _TarjetaSolicitud extends StatelessWidget {
  final SolicitudResumenModel s;

  const _TarjetaSolicitud({required this.s});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.superficie,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(
          s.nombreCliente.isEmpty ? 'Solicitud' : s.nombreCliente,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'S/ ${s.monto.toStringAsFixed(0)} · ${s.estado?.etiqueta ?? ''}',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: const Icon(Icons.fact_check_outlined, color: AppTheme.amarillo),
        onTap: () => abrirEvaluacionAdmin(context, s.id),
      ),
    );
  }
}

class _RevisionDocumentosAdmin extends StatelessWidget {
  const _RevisionDocumentosAdmin();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminRevisionDocumentosViewModel>();
    final ancho = MediaQuery.sizeOf(context).width;
    final usarPanelLateral = ancho > 900;

    if (vm.cargandoLista) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.amarillo),
      );
    }

    if (vm.lista.isEmpty) {
      return const Center(
        child: Text(
          'No hay solicitudes con documentos adjuntados',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    if (usarPanelLateral) {
      return Row(
        children: [
          SizedBox(
            width: 360,
            child: _ListaDocumentos(
              lista: vm.lista,
              seleccionada: vm.solicitudSeleccionada,
              onSeleccionar: (id) => vm.cargarDocumentos(id),
            ),
          ),
          const VerticalDivider(width: 1, color: Colors.white12),
          Expanded(
            child: vm.solicitudSeleccionada == null
                ? const Center(
                    child: Text(
                      'Selecciona una solicitud para revisar sus documentos',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : AdminDetalleDocumentosPanel(
                    solicitudId: vm.solicitudSeleccionada!,
                    slots: vm.slots,
                    cargando: vm.cargandoDetalle,
                    onEvaluar: () =>
                        abrirEvaluacionAdmin(context, vm.solicitudSeleccionada!),
                    onVerDocumento: (titulo, url) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VisorDocumentoScreen(
                            titulo: titulo,
                            imageUrl: url,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    }

    if (vm.solicitudSeleccionada != null) {
      return AdminDetalleDocumentosPanel(
        solicitudId: vm.solicitudSeleccionada!,
        slots: vm.slots,
        cargando: vm.cargandoDetalle,
        onVolver: () => vm.limpiarDetalle(),
        onEvaluar: () =>
            abrirEvaluacionAdmin(context, vm.solicitudSeleccionada!),
        onVerDocumento: (titulo, url) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VisorDocumentoScreen(
                titulo: titulo,
                imageUrl: url,
              ),
            ),
          );
        },
      );
    }

    return _ListaDocumentos(
      lista: vm.lista,
      seleccionada: vm.solicitudSeleccionada,
      onSeleccionar: (id) => vm.cargarDocumentos(id),
    );
  }
}

class _ListaDocumentos extends StatelessWidget {
  final List lista;
  final String? seleccionada;
  final void Function(String id) onSeleccionar;

  const _ListaDocumentos({
    required this.lista,
    required this.seleccionada,
    required this.onSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () =>
          context.read<AdminRevisionDocumentosViewModel>().cargarLista(),
      color: AppTheme.amarillo,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: lista.length,
        itemBuilder: (_, i) {
          final s = lista[i];
          final activa = seleccionada == s.solicitudId;
          return Card(
            color: activa
                ? AppTheme.navy.withValues(alpha: 0.6)
                : AppTheme.superficie,
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: s.documentacionCompleta
                    ? AppTheme.verdePendiente.withValues(alpha: 0.2)
                    : AppTheme.naranjaNuevo.withValues(alpha: 0.2),
                child: Icon(
                  s.documentacionCompleta
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_rounded,
                  color: s.documentacionCompleta
                      ? AppTheme.verdePendiente
                      : AppTheme.naranjaNuevo,
                  size: 20,
                ),
              ),
              title: Text(
                s.nombreCliente.isEmpty ? 'Solicitud' : s.nombreCliente,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'S/ ${s.monto.toStringAsFixed(0)} · '
                '${s.documentosSubidos}/${s.documentosObligatorios} docs · '
                '${s.estado ?? ''}',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.white38),
              onTap: () => onSeleccionar(s.solicitudId),
            ),
          );
        },
      ),
    );
  }
}
