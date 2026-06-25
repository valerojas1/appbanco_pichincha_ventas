import 'package:flutter/material.dart';
import '../../home/consulta_buro_screen.dart';
import '../../home/pre_evaluacion_screen.dart';
import '../../home/scoring_view.dart';
import '../../../ui/theme/app_theme.dart';
import 'widgets/admin_content_header.dart';

class AdminEvaluacionScreen extends StatelessWidget {
  const AdminEvaluacionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AdminContentHeader(
            titulo: 'Evaluación',
            subtitulo:
                'Consulta buró, pre-evaluación y scoring de crédito',
          ),
          const TabBar(
            indicatorColor: AppTheme.amarillo,
            labelColor: AppTheme.amarillo,
            unselectedLabelColor: Colors.white54,
            isScrollable: true,
            tabs: [
              Tab(text: 'Consulta buró'),
              Tab(text: 'Pre-evaluación'),
              Tab(text: 'Scoring crédito'),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                ConsultaBuroScreen(embedded: true),
                PreEvaluacionScreen(embedded: true),
                ScoringView(embedded: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
