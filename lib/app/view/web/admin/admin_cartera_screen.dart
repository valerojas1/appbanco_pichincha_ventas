import 'package:flutter/material.dart';
import '../../home/cartera_diaria_screen.dart';
import '../../home/monitor_asesores_screen.dart';
import '../../../ui/theme/app_theme.dart';
import 'widgets/admin_content_header.dart';

class AdminCarteraScreen extends StatelessWidget {
  const AdminCarteraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AdminContentHeader(
            titulo: 'Cartera',
            subtitulo:
                'Supervisión de cartera diaria y ubicación de asesores en campo',
          ),
          const TabBar(
            indicatorColor: AppTheme.amarillo,
            labelColor: AppTheme.amarillo,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'Cartera del día'),
              Tab(text: 'Monitor asesores'),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                CarteraDiariaScreen(embedded: true),
                MonitorAsesoresScreen(embedded: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
