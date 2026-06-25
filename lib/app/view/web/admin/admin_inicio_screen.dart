import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../navigation/admin_web_routes.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../viewmodel/admin_web_inicio_viewmodel.dart';
import '../../../viewmodel/auth_oficial_viewmodel.dart';
import 'widgets/acceso_rapido_card.dart';
import 'widgets/admin_content_header.dart';
import 'widgets/admin_kpi_card.dart';

class AdminInicioScreen extends StatefulWidget {
  final void Function(String ruta) onNavegar;

  const AdminInicioScreen({super.key, required this.onNavegar});

  @override
  State<AdminInicioScreen> createState() => _AdminInicioScreenState();
}

class _AdminInicioScreenState extends State<AdminInicioScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminWebInicioViewModel>().cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final oficial = context.watch<AuthOficialViewModel>().oficial;
    final vm = context.watch<AdminWebInicioViewModel>();
    final resumen = vm.resumen;

    return RefreshIndicator(
      onRefresh: () => context.read<AdminWebInicioViewModel>().cargar(),
      color: AppTheme.amarillo,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminContentHeader(
              titulo: 'Bienvenido, ${oficial?.nombre ?? 'Administrador'}',
              subtitulo:
                  'Panel de supervisión — revisa documentación y gestiona expedientes',
            ),
            if (vm.cargando)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.amarillo),
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final ancho = constraints.maxWidth;
                    final columnas = ancho > 900 ? 4 : (ancho > 500 ? 2 : 1);
                    final tarjetas = [
                      AdminKpiCard(
                        etiqueta: 'Docs adjuntados',
                        valor: '${resumen?.solicitudesConDocumentos ?? 0}',
                        icono: Icons.folder_copy_outlined,
                        color: AppTheme.azulVisitado,
                      ),
                      AdminKpiCard(
                        etiqueta: 'Pendientes revisión',
                        valor: '${resumen?.pendientesRevision ?? 0}',
                        icono: Icons.pending_actions_outlined,
                        color: AppTheme.naranjaNuevo,
                      ),
                      AdminKpiCard(
                        etiqueta: 'Recibidas',
                        valor: '${resumen?.solicitudesRecibidas ?? 0}',
                        icono: Icons.inbox_outlined,
                        color: Colors.tealAccent,
                      ),
                      AdminKpiCard(
                        etiqueta: 'En evaluación',
                        valor: '${resumen?.solicitudesEnEvaluacion ?? 0}',
                        icono: Icons.rate_review_outlined,
                        color: Colors.deepPurpleAccent,
                      ),
                      AdminKpiCard(
                        etiqueta: 'Aprobadas',
                        valor: '${resumen?.solicitudesAprobadas ?? 0}',
                        icono: Icons.check_circle_outline,
                        color: AppTheme.verdePendiente,
                      ),
                      AdminKpiCard(
                        etiqueta: 'Condicionadas',
                        valor: '${resumen?.solicitudesCondicionadas ?? 0}',
                        icono: Icons.tune_outlined,
                        color: Colors.amberAccent,
                      ),
                    ];
                    return GridView.count(
                      crossAxisCount: columnas,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: ancho > 500 ? 2.8 : 2.4,
                      children: tarjetas,
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 28),
                child: Text(
                  'Accesos rápidos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final ancho = constraints.maxWidth;
                    final columnas = ancho > 900 ? 3 : (ancho > 600 ? 2 : 1);
                    final atajos = _buildAtajos();
                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columnas,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: ancho > 600 ? 3.2 : 2.6,
                      ),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: atajos.length,
                      itemBuilder: (_, i) => atajos[i],
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAtajos() {
    return [
      AccesoRapidoCard(
        icono: Icons.assignment_outlined,
        colorIcono: const Color(0xFFE53935),
        fondoIcono: const Color(0x33E53935),
        titulo: 'Cartera del día',
        descripcion: 'Clientes asignados para visitar hoy',
        onTap: () => widget.onNavegar(AdminWebRoutes.cartera),
      ),
      AccesoRapidoCard(
        icono: Icons.folder_open_outlined,
        colorIcono: const Color(0xFF00897B),
        fondoIcono: const Color(0x3300897B),
        titulo: 'Revisar documentos',
        descripcion: 'Expedientes adjuntados por operadores',
        onTap: () => widget.onNavegar(AdminWebRoutes.solicitudes),
      ),
      AccesoRapidoCard(
        icono: Icons.verified_user_outlined,
        colorIcono: const Color(0xFF7B1FA2),
        fondoIcono: const Color(0x337B1FA2),
        titulo: 'Pre-evaluar / Buró',
        descripcion: 'Capacidad de pago y listas negras',
        onTap: () => widget.onNavegar(AdminWebRoutes.evaluacion),
      ),
      AccesoRapidoCard(
        icono: Icons.payments_outlined,
        colorIcono: const Color(0xFFEF6C00),
        fondoIcono: const Color(0x33EF6C00),
        titulo: 'Cobranza',
        descripcion: 'Gestión de mora del día',
        onTap: () => widget.onNavegar(AdminWebRoutes.cobranza),
      ),
      AccesoRapidoCard(
        icono: Icons.track_changes_outlined,
        colorIcono: const Color(0xFFD81B60),
        fondoIcono: const Color(0x33D81B60),
        titulo: 'Estado solicitudes',
        descripcion: 'Tablero de estado de expedientes',
        onTap: () => widget.onNavegar(AdminWebRoutes.solicitudes),
      ),
      AccesoRapidoCard(
        icono: Icons.bar_chart_outlined,
        colorIcono: const Color(0xFF43A047),
        fondoIcono: const Color(0x3343A047),
        titulo: 'Reportes',
        descripcion: 'Productividad del equipo',
        onTap: () => widget.onNavegar(AdminWebRoutes.reportes),
      ),
    ];
  }
}
