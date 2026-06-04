import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/campana_activa_model.dart';
import '../../model/preevaluacion_resultado_model.dart';
import '../../viewmodel/dashboard_viewmodel.dart';
import '../../viewmodel/auth_oficial_viewmodel.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/oficial_scaffold.dart';
import 'ficha_cliente_screen.dart';
import 'pre_evaluacion_screen.dart';
import 'widgets/campanas_activas_section.dart';

class DashboardView extends StatefulWidget {
  final bool embedded;

  const DashboardView({super.key, this.embedded = false});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  String? _asesorid;

  @override
  void initState() {
    super.initState();
    _asesorid = context.read<AuthOficialViewModel>().oficial?.asesorid;
    if (_asesorid != null) {
      context.read<DashboardViewModel>().cargarDashboard(_asesorid!);
    }
  }

  Future<void> _recargar() async {
    if (_asesorid != null) {
      await context.read<DashboardViewModel>().recargar(_asesorid!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();

    return OficialScaffold(
      embedded: widget.embedded,
      title: 'Dashboard Asesor',
      body: vm.loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.amarillo))
          : vm.dashboard == null
              ? const Center(child: Text('Sin datos disponibles',
                  style: TextStyle(color: Colors.white54)))
              : RefreshIndicator(
                  onRefresh: _recargar,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hola, ${vm.dashboard!.nombreasesor}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      CampanasActivasSection(
                        campanas: vm.campanas,
                        onGestionar: (c) => _gestionarCampana(context, c),
                      ),
                      const SizedBox(height: 24),
                      _KpiCard(
                        label: 'Visitas hoy',
                        value: '${vm.dashboard!.visitashoy}',
                        icon: Icons.tour,
                        color: AppTheme.amarillo,
                      ),
                      const SizedBox(height: 12),
                      _KpiCard(
                        label: 'Visitas completadas',
                        value: '${vm.dashboard!.visitascompletadas}',
                        icon: Icons.check_circle,
                        color: AppTheme.verdePendiente,
                      ),
                      const SizedBox(height: 12),
                      _KpiCard(
                        label: 'Créditos colocados',
                        value: '${vm.dashboard!.creditoscolocados}',
                        icon: Icons.attach_money,
                        color: AppTheme.azulVisitado,
                      ),
                      const SizedBox(height: 12),
                      _KpiCard(
                        label: 'Monto colocado',
                        value: 'S/ ${vm.dashboard!.montocolocado.toStringAsFixed(2)}',
                        icon: Icons.trending_up,
                        color: AppTheme.naranjaNuevo,
                      ),
                      const SizedBox(height: 12),
                      _KpiCard(
                        label: 'Clientes nuevos',
                        value: '${vm.dashboard!.clientesnuevos}',
                        icon: Icons.person_add,
                        color: Colors.tealAccent,
                      ),
                      const SizedBox(height: 12),
                      _KpiCard(
                        label: 'Solicitudes pendientes',
                        value: '${vm.dashboard!.solicitudespendientes}',
                        icon: Icons.pending,
                        color: Colors.orangeAccent,
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  void _gestionarCampana(BuildContext context, CampanaActivaModel c) {
    if (c.clienteid != null && c.clienteid!.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FichaClienteScreen(
            args: FichaClienteArgs(
              clienteId: c.clienteid,
              documento: '',
              nombreFallback: c.nombrecliente,
            ),
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PreEvaluacionScreen(
            prefill: ProspectoSolicitudPrefill(
              dni: '',
              nombres: c.nombrecliente,
              tiponegocio: '',
              ingresos: 0,
              destino: 'capital_trabajo',
              monto: c.montooferta,
            ),
          ),
        ),
      );
    }
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 14),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
