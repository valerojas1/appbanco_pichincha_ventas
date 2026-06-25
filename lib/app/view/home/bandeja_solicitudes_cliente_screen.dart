import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/solicitud_credito_data.dart';
import '../../services/solicitud_bandeja_cliente_service.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/oficial_scaffold.dart';
import '../../viewmodel/auth_oficial_viewmodel.dart';
import '../../viewmodel/bandeja_solicitudes_cliente_viewmodel.dart';
import '../../viewmodel/solicitud_credito_viewmodel.dart';
import 'solicitud_credito_wizard_screen.dart';

/// Bandeja global de solicitudes enviadas por clientes (app cliente).
class BandejaSolicitudesClienteScreen extends StatefulWidget {
  final bool embedded;

  const BandejaSolicitudesClienteScreen({
    super.key,
    this.embedded = false,
  });

  @override
  State<BandejaSolicitudesClienteScreen> createState() =>
      _BandejaSolicitudesClienteScreenState();
}

class _BandejaSolicitudesClienteScreenState
    extends State<BandejaSolicitudesClienteScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  void _cargar() {
    final asesor = context.read<AuthOficialViewModel>().oficial?.asesorid;
    if (asesor != null) {
      context.read<BandejaSolicitudesClienteViewModel>().cargar(asesor);
    }
  }

  Future<void> _abrirWizard(SolicitudCreditoData data) async {
    if (!mounted) return;
    final asesor = context.read<AuthOficialViewModel>().oficial?.asesorid;
    if (asesor != null) {
      context.read<SolicitudCreditoViewModel>().iniciar(
            asesorid: asesor,
            existente: data,
          );
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SolicitudCreditoWizardScreen(
          key: ValueKey(
            data.solicitudIdServidor ??
                data.borradorIdLocal ??
                '${data.dni}_${DateTime.now().microsecondsSinceEpoch}',
          ),
          borradorExistente: data,
        ),
      ),
    );
    _cargar();
  }

  Future<void> _tomar(SolicitudBandejaClienteResumen s) async {
    final asesor = context.read<AuthOficialViewModel>().oficial?.asesorid;
    if (asesor == null) return;

    final vm = context.read<BandejaSolicitudesClienteViewModel>();
    final datos = await vm.tomar(solicitudId: s.id, asesorid: asesor);
    if (!mounted) return;

    if (datos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.error ?? 'No se pudo tomar la solicitud'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    await _abrirWizard(datos);
  }

  Future<void> _continuar(SolicitudBandejaClienteResumen s) async {
    final asesor = context.read<AuthOficialViewModel>().oficial?.asesorid;
    if (asesor == null) return;

    final datos = await context
        .read<BandejaSolicitudesClienteViewModel>()
        .continuar(solicitudId: s.id, asesorid: asesor);
    if (!mounted || datos == null) return;
    await _abrirWizard(datos);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BandejaSolicitudesClienteViewModel>();

    return OficialScaffold(
      embedded: widget.embedded,
      title: 'Solicitudes de clientes',
      body: Column(
        children: [
          if (vm.error != null)
            Material(
              color: Colors.redAccent.withValues(alpha: 0.15),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        vm.error!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          TabBar(
            controller: _tabs,
            indicatorColor: AppTheme.amarillo,
            labelColor: AppTheme.amarillo,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'Nuevas (${vm.pendientes.length})'),
              Tab(text: 'Mis en atención (${vm.enAtencion.length})'),
            ],
          ),
          if (vm.procesando)
            const LinearProgressIndicator(color: AppTheme.amarillo),
          Expanded(
            child: vm.cargando
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.amarillo),
                  )
                : TabBarView(
                    controller: _tabs,
                    children: [
                      _ListaBandeja(
                        lista: vm.pendientes,
                        vacio:
                            'No hay solicitudes nuevas de clientes en este momento.',
                        accion: _tomar,
                        etiquetaBoton: 'ATENDER',
                        iconoBoton: Icons.person_pin_circle_outlined,
                        onRefresh: _cargar,
                      ),
                      _ListaBandeja(
                        lista: vm.enAtencion,
                        vacio: 'No tiene solicitudes en atención.',
                        accion: _continuar,
                        etiquetaBoton: 'CONTINUAR',
                        iconoBoton: Icons.edit_note_outlined,
                        onRefresh: _cargar,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ListaBandeja extends StatelessWidget {
  final List<SolicitudBandejaClienteResumen> lista;
  final String vacio;
  final Future<void> Function(SolicitudBandejaClienteResumen) accion;
  final String etiquetaBoton;
  final IconData iconoBoton;
  final VoidCallback onRefresh;

  const _ListaBandeja({
    required this.lista,
    required this.vacio,
    required this.accion,
    required this.etiquetaBoton,
    required this.iconoBoton,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (lista.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => onRefresh(),
        color: AppTheme.amarillo,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 80),
            Icon(Icons.inbox_outlined, size: 48, color: Colors.white24),
            const SizedBox(height: 12),
            Text(
              vacio,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppTheme.amarillo,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: lista.length,
        itemBuilder: (_, i) {
          final s = lista[i];
          return Card(
            color: AppTheme.superficie,
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.nombreCliente.isEmpty ? 'Cliente' : s.nombreCliente,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (s.origen == 'app_cliente')
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.azulVisitado.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'App cliente',
                            style: TextStyle(
                              color: AppTheme.azulVisitado,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'DNI ${s.dni} · S/ ${s.monto.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  if (s.tipoNegocio != null && s.tipoNegocio!.isNotEmpty)
                    Text(
                      s.tipoNegocio!,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  if (s.destinoCredito != null && s.destinoCredito!.isNotEmpty)
                    Text(
                      s.destinoCredito!,
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  if (s.direccionNegocio != null &&
                      s.direccionNegocio!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppTheme.amarillo,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              s.direccionNegocio!,
                              style: const TextStyle(
                                color: AppTheme.amarillo,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (s.tieneCoordenadasNegocio)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.my_location,
                            size: 14,
                            color: AppTheme.verdePendiente,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'GPS: ${s.latitudNegocio!.toStringAsFixed(5)}, '
                              '${s.longitudNegocio!.toStringAsFixed(5)}',
                              style: const TextStyle(
                                color: AppTheme.verdePendiente,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => accion(s),
                    icon: Icon(iconoBoton, size: 18),
                    label: Text(etiquetaBoton),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.amarillo,
                      foregroundColor: AppTheme.navyOscuro,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
