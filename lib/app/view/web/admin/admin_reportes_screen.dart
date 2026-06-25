import 'package:flutter/material.dart';
import '../../home/dashboard_view.dart';
import '../../home/metas_view.dart';
import '../../home/reporte_productividad_screen.dart';
import '../../../ui/theme/app_theme.dart';
import 'widgets/admin_content_header.dart';

class AdminReportesScreen extends StatelessWidget {
  const AdminReportesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AdminContentHeader(
            titulo: 'Reportes',
            subtitulo: 'Productividad del equipo, metas y dashboard general',
          ),
          const TabBar(
            indicatorColor: AppTheme.amarillo,
            labelColor: AppTheme.amarillo,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'Productividad mensual'),
              Tab(text: 'Metas del mes'),
              Tab(text: 'Dashboard'),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                ReporteProductividadScreen(embedded: true),
                MetasView(embedded: true),
                DashboardView(embedded: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
