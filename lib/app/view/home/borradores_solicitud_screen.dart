import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/oficial_scaffold.dart';
import '../../viewmodel/auth_oficial_viewmodel.dart';
import '../../viewmodel/solicitud_credito_viewmodel.dart';
import '../../core/buro_solicitud_gate.dart';
import 'solicitud_credito_wizard_screen.dart';

class BorradoresSolicitudScreen extends StatefulWidget {
  final bool embedded;

  const BorradoresSolicitudScreen({super.key, this.embedded = false});

  @override
  State<BorradoresSolicitudScreen> createState() =>
      _BorradoresSolicitudScreenState();
}

class _BorradoresSolicitudScreenState extends State<BorradoresSolicitudScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    final asesor = context.read<AuthOficialViewModel>().oficial?.asesorid;
    if (asesor != null) {
      await context.read<SolicitudCreditoViewModel>().cargarBorradores(asesor);
    }
  }

  Future<void> _abrirBorrador(String borradorId) async {
    final asesor = context.read<AuthOficialViewModel>().oficial?.asesorid;
    if (asesor == null) return;
    final vm = context.read<SolicitudCreditoViewModel>();
    final data = await vm.cargarBorradorPorId(borradorId);
    if (!mounted || data == null) return;
    final ok = await BuroSolicitudGate.validarAntesDeSolicitud(
      context,
      dni: data.dni,
      nombres: '${data.nombres} ${data.apellidos}'.trim(),
    );
    if (!mounted || !ok) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SolicitudCreditoWizardScreen(
          borradorExistente: data,
        ),
      ),
    );
    await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SolicitudCreditoViewModel>();

    return OficialScaffold(
      embedded: widget.embedded,
      title: 'Borradores',
      body: vm.borradores.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(
                  child: Text(
                    'No hay borradores guardados',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ],
            )
          : RefreshIndicator(
              onRefresh: _cargar,
              color: AppTheme.amarillo,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: vm.borradores.length,
                itemBuilder: (context, index) {
                  final b = vm.borradores[index];
                  final fecha = DateTime.tryParse(b.fechaActualizacion);
                  final fechaTxt = fecha != null
                      ? '${fecha.day}/${fecha.month}/${fecha.year}'
                      : b.fechaActualizacion;

                  return Dismissible(
                    key: ValueKey(b.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) => vm.eliminarBorrador(b.id),
                    child: Card(
                      color: AppTheme.superficie,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        onTap: () => _abrirBorrador(b.id),
                        title: Text(
                          b.nombre,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Paso ${b.pasoAlcanzado}/4 · $fechaTxt · S/ ${b.monto.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.white38,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
