import 'package:flutter/material.dart';
import '../model/perfil_oficial.dart';
import 'app_router.dart';

class MenuItemConfig {
  final String id;
  final String titulo;
  final IconData icono;
  final String route;
  final Set<PerfilOficial> perfiles;

  const MenuItemConfig({
    required this.id,
    required this.titulo,
    required this.icono,
    required this.route,
    required this.perfiles,
  });
}

class MenuConfig {
  static const List<MenuItemConfig> _todos = [
    MenuItemConfig(
      id: 'clientes',
      titulo: 'Clientes Pichincha',
      icono: Icons.account_balance,
      route: AppRouter.home,
      perfiles: {
        PerfilOficial.operador,
        PerfilOficial.superoperador,
        PerfilOficial.supervisor,
        PerfilOficial.administrador,
      },
    ),
    MenuItemConfig(
      id: 'bandeja_clientes',
      titulo: 'Solicitudes clientes',
      icono: Icons.inbox_outlined,
      route: AppRouter.bandejaSolicitudesCliente,
      perfiles: {
        PerfilOficial.operador,
        PerfilOficial.superoperador,
        PerfilOficial.supervisor,
        PerfilOficial.administrador,
      },
    ),
    MenuItemConfig(
      id: 'dashboard',
      titulo: 'Dashboard',
      icono: Icons.dashboard_outlined,
      route: AppRouter.dashboard,
      perfiles: {
        PerfilOficial.superoperador,
        PerfilOficial.supervisor,
        PerfilOficial.administrador,
      },
    ),
    MenuItemConfig(
      id: 'ruta',
      titulo: 'Planificación de ruta',
      icono: Icons.map_outlined,
      route: AppRouter.ruta,
      perfiles: {
        PerfilOficial.operador,
        PerfilOficial.superoperador,
        PerfilOficial.supervisor,
        PerfilOficial.administrador,
      },
    ),
    MenuItemConfig(
      id: 'ficha',
      titulo: 'Ficha de campo',
      icono: Icons.description_outlined,
      route: AppRouter.ficha,
      perfiles: {
        PerfilOficial.operador,
        PerfilOficial.superoperador,
        PerfilOficial.supervisor,
        PerfilOficial.administrador,
      },
    ),
    MenuItemConfig(
      id: 'cartera',
      titulo: 'Cartera del día',
      icono: Icons.assignment_outlined,
      route: AppRouter.cartera,
      perfiles: {
        PerfilOficial.operador,
        PerfilOficial.superoperador,
        PerfilOficial.supervisor,
        PerfilOficial.administrador,
      },
    ),
    MenuItemConfig(
      id: 'cartera_vencida',
      titulo: 'Cartera vencida',
      icono: Icons.warning_amber_rounded,
      route: AppRouter.carteraVencida,
      perfiles: {
        PerfilOficial.operador,
        PerfilOficial.superoperador,
        PerfilOficial.supervisor,
        PerfilOficial.administrador,
      },
    ),
    MenuItemConfig(
      id: 'documentos',
      titulo: 'Captura documentos',
      icono: Icons.folder_copy_outlined,
      route: AppRouter.documentosSolicitud,
      perfiles: {
        PerfilOficial.operador,
        PerfilOficial.superoperador,
        PerfilOficial.supervisor,
        PerfilOficial.administrador,
      },
    ),
    MenuItemConfig(
      id: 'solicitud_credito',
      titulo: 'Solicitud de crédito',
      icono: Icons.request_quote_outlined,
      route: AppRouter.solicitudCredito,
      perfiles: {
        PerfilOficial.operador,
        PerfilOficial.superoperador,
        PerfilOficial.supervisor,
        PerfilOficial.administrador,
      },
    ),
    MenuItemConfig(
      id: 'estado_solicitudes',
      titulo: 'Estado solicitudes',
      icono: Icons.track_changes_outlined,
      route: AppRouter.estadoSolicitudes,
      perfiles: {
        PerfilOficial.operador,
        PerfilOficial.superoperador,
        PerfilOficial.supervisor,
        PerfilOficial.administrador,
      },
    ),
    MenuItemConfig(
      id: 'borradores',
      titulo: 'Borradores',
      icono: Icons.drafts_outlined,
      route: AppRouter.borradoresSolicitud,
      perfiles: {
        PerfilOficial.operador,
        PerfilOficial.superoperador,
        PerfilOficial.supervisor,
        PerfilOficial.administrador,
      },
    ),
    MenuItemConfig(
      id: 'consulta_buro',
      titulo: 'Consulta buró',
      icono: Icons.verified_user_outlined,
      route: AppRouter.consultaBuro,
      perfiles: {
        PerfilOficial.operador,
        PerfilOficial.superoperador,
        PerfilOficial.supervisor,
        PerfilOficial.administrador,
      },
    ),
    MenuItemConfig(
      id: 'prospeccion',
      titulo: 'Pre-evaluación',
      icono: Icons.fact_check_outlined,
      route: AppRouter.prospeccion,
      perfiles: {
        PerfilOficial.operador,
        PerfilOficial.superoperador,
        PerfilOficial.supervisor,
        PerfilOficial.administrador,
      },
    ),
    MenuItemConfig(
      id: 'desertor',
      titulo: 'Cliente desertor',
      icono: Icons.person_off_outlined,
      route: AppRouter.clienteDesertor,
      perfiles: {
        PerfilOficial.operador,
        PerfilOficial.superoperador,
        PerfilOficial.supervisor,
        PerfilOficial.administrador,
      },
    ),
    MenuItemConfig(
      id: 'scoring',
      titulo: 'Scoring crédito',
      icono: Icons.analytics_outlined,
      route: AppRouter.scoring,
      perfiles: {
        PerfilOficial.superoperador,
        PerfilOficial.supervisor,
        PerfilOficial.administrador,
      },
    ),
    MenuItemConfig(
      id: 'metas',
      titulo: 'Metas del mes',
      icono: Icons.flag_outlined,
      route: AppRouter.metas,
      perfiles: {
        PerfilOficial.superoperador,
        PerfilOficial.supervisor,
        PerfilOficial.administrador,
      },
    ),
    MenuItemConfig(
      id: 'monitor_asesores',
      titulo: 'Monitor asesores',
      icono: Icons.map_outlined,
      route: AppRouter.monitorAsesores,
      perfiles: {
        PerfilOficial.supervisor,
        PerfilOficial.administrador,
      },
    ),
    MenuItemConfig(
      id: 'reporte_productividad',
      titulo: 'Productividad mensual',
      icono: Icons.bar_chart_outlined,
      route: AppRouter.reporteProductividad,
      perfiles: {
        PerfilOficial.supervisor,
        PerfilOficial.administrador,
      },
    ),
  ];

  static List<MenuItemConfig> itemsFor(PerfilOficial perfil) {
    return _todos.where((item) => item.perfiles.contains(perfil)).toList();
  }
}
