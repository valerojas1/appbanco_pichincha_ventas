import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/auth_oficial_viewmodel.dart';
import '../../viewmodel/clientes_credito_viewmodel.dart';
import '../../viewmodel/prospeccion_viewmodel.dart';
import '../../ui/theme/app_theme.dart';
import 'pre_evaluacion_screen.dart';
import 'widgets/tarjeta_cliente_financiero.dart';
import 'widgets/campanas_activas_section.dart';
import 'ficha_cliente_screen.dart';

class ProspectosCreditoTab extends StatefulWidget {
  const ProspectosCreditoTab({super.key});

  @override
  State<ProspectosCreditoTab> createState() => _ProspectosCreditoTabState();
}

class _ProspectosCreditoTabState extends State<ProspectosCreditoTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final asesor = context.read<AuthOficialViewModel>().oficial?.asesorid;
      if (asesor != null) {
        context.read<ProspeccionViewModel>().cargarCampanas(asesor);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ClientesCreditoViewModel>();
    final prospeccionVm = context.watch<ProspeccionViewModel>();

    if (vm.loadingProspectos) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.amarillo),
      );
    }

    if (vm.errorProspectos != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(vm.errorProspectos!,
                style: const TextStyle(color: Colors.white54)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: vm.cargarProspectos,
              child: const Text('Reintentar',
                  style: TextStyle(color: AppTheme.amarillo)),
            ),
          ],
        ),
      );
    }

    final conScoring =
        vm.prospectos.where((p) => p.tieneScoring).length;
    final sinScoring = vm.totalProspectos - conScoring;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PreEvaluacionScreen()),
          );
        },
        backgroundColor: AppTheme.amarillo,
        foregroundColor: AppTheme.navy,
        icon: const Icon(Icons.fact_check),
        label: const Text('Pre-evaluar'),
      ),
      body: RefreshIndicator(
      onRefresh: () async {
        await vm.cargarProspectos();
        final asesor = context.read<AuthOficialViewModel>().oficial?.asesorid;
        if (asesor != null) {
          await context.read<ProspeccionViewModel>().cargarCampanas(asesor);
        }
      },
      color: AppTheme.amarillo,
      child: vm.prospectos.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(
                  child: Text(
                    'No hay prospectos de crédito registrados',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ],
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                CampanasActivasSection(
                  campanas: prospeccionVm.campanas,
                  onGestionar: (c) {
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
                          builder: (_) => const PreEvaluacionScreen(),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.superficie,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.naranjaNuevo.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Posibles clientes — Evaluación de crédito',
                        style: TextStyle(
                          color: AppTheme.naranjaNuevo,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${vm.totalProspectos} prospectos · $conScoring con scoring · $sinScoring por evaluar',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Datos financieros declarados y scoring transaccional '
                        'para decidir elegibilidad de préstamo.',
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ...vm.prospectos.map(
                  (c) => TarjetaClienteFinanciero(
                    cliente: c,
                    mostrarDetalleCredito: true,
                  ),
                ),
              ],
            ),
      ),
    );
  }
}
