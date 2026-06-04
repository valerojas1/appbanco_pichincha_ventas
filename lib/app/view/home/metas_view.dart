import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/metas_viewmodel.dart';
import '../../viewmodel/auth_oficial_viewmodel.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/oficial_scaffold.dart';

class MetasView extends StatefulWidget {
  final bool embedded;

  const MetasView({super.key, this.embedded = false});

  @override
  State<MetasView> createState() => _MetasViewState();
}

class _MetasViewState extends State<MetasView> {
  @override
  void initState() {
    super.initState();
    final oficial = context.read<AuthOficialViewModel>().oficial;
    if (oficial != null) {
      context.read<MetasViewModel>().cargarMetas(oficial.userid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MetasViewModel>();

    final meses = [
      '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Setiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    return OficialScaffold(
      embedded: widget.embedded,
      title: 'Metas del Mes',
      body: vm.loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.amarillo))
          : vm.metas == null
              ? const Center(child: Text('Sin metas para este mes',
                  style: TextStyle(color: Colors.white54)))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${meses[vm.metas!.mes]} ${vm.metas!.anio}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      _BarraProgreso(
                        label: 'Visitas',
                        logrado: vm.metas!.visitaslogradas,
                        meta: vm.metas!.metasvisitas,
                        color: AppTheme.verdePendiente,
                        unidad: 'visitas',
                      ),
                      const SizedBox(height: 20),
                      _BarraProgreso(
                        label: 'Créditos',
                        logrado: vm.metas!.creditoslogrados,
                        meta: vm.metas!.metascreditos,
                        color: AppTheme.azulVisitado,
                        unidad: 'créditos',
                      ),
                      const SizedBox(height: 20),
                      _BarraProgreso(
                        label: 'Monto Colocado',
                        logrado: vm.metas!.montologistrado.toInt(),
                        meta: vm.metas!.metasmonot.toInt(),
                        color: AppTheme.naranjaNuevo,
                        unidad: 'S/',
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _BarraProgreso extends StatelessWidget {
  final String label;
  final int logrado;
  final int meta;
  final Color color;
  final String unidad;

  const _BarraProgreso({
    required this.label,
    required this.logrado,
    required this.meta,
    required this.color,
    required this.unidad,
  });

  @override
  Widget build(BuildContext context) {
    final progreso = meta > 0 ? logrado / meta : 0.0;
    final porcentaje = (progreso * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
            Text('$logrado / $meta $unidad',
                style: TextStyle(color: color, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progreso.clamp(0.0, 1.0),
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text('$porcentaje%',
            style: TextStyle(color: color.withOpacity(0.7), fontSize: 11)),
      ],
    );
  }
}
