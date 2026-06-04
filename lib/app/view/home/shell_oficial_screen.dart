import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../navigation/app_router.dart';
import '../../navigation/menu_config.dart';
import '../../viewmodel/auth_oficial_viewmodel.dart';
import '../../viewmodel/offline_sync_viewmodel.dart';
import '../../viewmodel/clientes_credito_viewmodel.dart';
import '../../ui/theme/app_theme.dart';
import 'clientes_pichincha_tab.dart';
import 'prospectos_credito_tab.dart';
import 'dashboard_view.dart';
import 'ruta_view.dart';
import 'ficha_view.dart';
import 'cartera_diaria_screen.dart';
import 'scoring_view.dart';
import 'metas_view.dart';
import 'pre_evaluacion_screen.dart';
import 'cliente_desertor_screen.dart';
import 'solicitud_credito_wizard_screen.dart';
import 'borradores_solicitud_screen.dart';
import 'seleccion_solicitud_documentos_screen.dart';
import 'consulta_buro_screen.dart';
import 'cartera_vencida_screen.dart';
import 'monitor_asesores_screen.dart';
import 'reporte_productividad_screen.dart';
import 'solicitudes_tablero_screen.dart';
import '../../ui/widgets/modo_offline_banner.dart';

class ShellOficialScreen extends StatefulWidget {
  const ShellOficialScreen({super.key});

  @override
  State<ShellOficialScreen> createState() => _ShellOficialScreenState();
}

class _ShellOficialScreenState extends State<ShellOficialScreen> {
  String _rutaActual = AppRouter.home;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_rutaActual == AppRouter.home) {
        context.read<ClientesCreditoViewModel>().cargarTodo();
      }
      context.read<OfflineSyncViewModel>().actualizarContadores();
    });
  }

  Future<void> _cerrarSesion() async {
    final authVm = context.read<AuthOficialViewModel>();
    final pendientes = await authVm.pendingSyncCount();

    if (!mounted) return;

    if (pendientes > 0) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.superficie,
          title: const Text(
            'Sincronización pendiente',
            style: TextStyle(color: AppTheme.amarillo),
          ),
          content: Text(
            'Tienes $pendientes registro(s) sin sincronizar (fichas y/o visitas). '
            'Si cierras sesión se borrará la caché local y podrías perder esos datos.\n\n'
            '¿Deseas cerrar sesión de todos modos?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Cerrar sesión',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ),
      );
      if (confirmar != true) return;
    }

    await authVm.logout();
  }

  Widget _contenidoPorRuta(String route) {
    switch (route) {
      case AppRouter.home:
        return const _ClientesProspectosTabs();
      case AppRouter.dashboard:
        return const DashboardView(embedded: true);
      case AppRouter.ruta:
        return const RutaView(embedded: true);
      case AppRouter.ficha:
        return const FichaView(embedded: true);
      case AppRouter.cartera:
        return const CarteraDiariaScreen(embedded: true);
      case AppRouter.carteraVencida:
        return const CarteraVencidaScreen(embedded: true);
      case AppRouter.monitorAsesores:
        return const MonitorAsesoresScreen(embedded: true);
      case AppRouter.reporteProductividad:
        return const ReporteProductividadScreen(embedded: true);
      case AppRouter.scoring:
        return const ScoringView(embedded: true);
      case AppRouter.metas:
        return const MetasView(embedded: true);
      case AppRouter.consultaBuro:
        return const ConsultaBuroScreen(embedded: true);
      case AppRouter.estadoSolicitudes:
        return const SolicitudesTableroScreen(embedded: true);
      case AppRouter.prospeccion:
        return const PreEvaluacionScreen(embedded: true);
      case AppRouter.clienteDesertor:
        return const ClienteDesertorScreen(embedded: true);
      case AppRouter.solicitudCredito:
        return const SolicitudCreditoWizardScreen();
      case AppRouter.borradoresSolicitud:
        return const BorradoresSolicitudScreen(embedded: true);
      case AppRouter.documentosSolicitud:
        return const SeleccionSolicitudDocumentosScreen(embedded: true);
      default:
        return const _ClientesProspectosTabs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final oficial = context.watch<AuthOficialViewModel>().oficial;
    if (oficial == null) return const SizedBox.shrink();

    final menuItems = MenuConfig.itemsFor(oficial.perfil);
    final tituloActual = menuItems
        .where((m) => m.route == _rutaActual)
        .map((m) => m.titulo)
        .firstOrNull;

    return Scaffold(
      backgroundColor: AppTheme.fondoOscuro,
      appBar: AppBar(
        title: Text(
          tituloActual ?? 'Portal Oficial',
          style: const TextStyle(
            color: AppTheme.amarillo,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: AppTheme.navyOscuro,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: AppTheme.superficie,
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.amarillo.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${oficial.nombre} ${oficial.apellido}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cód. ${oficial.codigoempleado}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.amarillo.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppTheme.amarillo.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        oficial.perfil.etiqueta.toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.amarillo,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: menuItems.map((item) {
                    final seleccionado = _rutaActual == item.route;
                    return ListTile(
                      leading: Icon(
                        item.icono,
                        color: seleccionado
                            ? AppTheme.amarillo
                            : Colors.white54,
                      ),
                      title: Text(
                        item.titulo,
                        style: TextStyle(
                          color: seleccionado
                              ? AppTheme.amarillo
                              : Colors.white,
                          fontWeight: seleccionado
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      selected: seleccionado,
                      onTap: () {
                        setState(() => _rutaActual = item.route);
                        if (item.route == AppRouter.home) {
                          context.read<ClientesCreditoViewModel>().cargarTodo();
                        }
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ),
              const Divider(color: Colors.white12),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text(
                  'Cerrar sesión',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _cerrarSesion();
                },
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          const ModoOfflineBanner(),
          Expanded(child: _contenidoPorRuta(_rutaActual)),
        ],
      ),
    );
  }
}

class _ClientesProspectosTabs extends StatefulWidget {
  const _ClientesProspectosTabs();

  @override
  State<_ClientesProspectosTabs> createState() => _ClientesProspectosTabsState();
}

class _ClientesProspectosTabsState extends State<_ClientesProspectosTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.amarillo,
          labelColor: AppTheme.amarillo,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(
              icon: Icon(Icons.account_balance, size: 20),
              text: 'Clientes Pichincha',
            ),
            Tab(
              icon: Icon(Icons.person_search, size: 20),
              text: 'Prospectos Crédito',
            ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              ClientesPichinchaTab(),
              ProspectosCreditoTab(),
            ],
          ),
        ),
      ],
    );
  }
}
