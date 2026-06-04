import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/productividad_asesor_model.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/oficial_scaffold.dart';
import '../../viewmodel/reporte_productividad_viewmodel.dart';

class ReporteProductividadScreen extends StatefulWidget {
  final bool embedded;

  const ReporteProductividadScreen({super.key, this.embedded = false});

  @override
  State<ReporteProductividadScreen> createState() =>
      _ReporteProductividadScreenState();
}

class _ReporteProductividadScreenState extends State<ReporteProductividadScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReporteProductividadViewModel>().cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReporteProductividadViewModel>();

    return OficialScaffold(
      embedded: widget.embedded,
      title: 'Productividad mensual',
      actions: [
        IconButton(
          onPressed: vm.exportando || vm.filas.isEmpty ? null : vm.exportarPdf,
          icon: vm.exportando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.picture_as_pdf, color: AppTheme.amarillo),
          tooltip: 'Exportar PDF',
        ),
      ],
      body: vm.cargando
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.amarillo),
            )
          : vm.filas.isEmpty
              ? const Center(
                  child: Text(
                    'Sin solicitudes en el mes actual',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (vm.error != null)
                        Text(
                          vm.error!,
                          style: const TextStyle(color: Colors.orangeAccent),
                        ),
                      SizedBox(
                        height: 220,
                        child: _GraficoBarras(filas: vm.filas),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Detalle por asesor',
                        style: TextStyle(
                          color: AppTheme.amarillo,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...vm.filas.map((f) => _FilaProductividad(fila: f)),
                    ],
                  ),
                ),
    );
  }
}

class _GraficoBarras extends StatelessWidget {
  final List<ProductividadAsesorModel> filas;

  const _GraficoBarras({required this.filas});

  @override
  Widget build(BuildContext context) {
    final top = filas.take(6).toList();
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: top
                .map((f) => f.desembolsadas.toDouble())
                .fold<double>(0, (a, b) => a > b ? a : b) +
            2,
        barGroups: [
          for (var i = 0; i < top.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: top[i].desembolsadas.toDouble(),
                  color: AppTheme.amarillo,
                  width: 14,
                ),
              ],
            ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= top.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    top[i].asesorid.length > 6
                        ? top[i].asesorid.substring(0, 6)
                        : top[i].asesorid,
                    style: const TextStyle(color: Colors.white54, fontSize: 9),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

class _FilaProductividad extends StatelessWidget {
  final ProductividadAsesorModel fila;

  const _FilaProductividad({required this.fila});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.superficie,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Asesor ${fila.asesorid}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Enviadas ${fila.enviadas} · Aprobadas ${fila.aprobadas} · '
              'Desembolsadas ${fila.desembolsadas}',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
            Text(
              'Monto S/ ${fila.montoDesembolsado.toStringAsFixed(0)} · '
              'Tasa ${fila.tasaAprobacion.toStringAsFixed(1)}%',
              style: const TextStyle(color: AppTheme.amarillo, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
