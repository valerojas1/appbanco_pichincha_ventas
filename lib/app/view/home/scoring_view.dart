import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/scoring_viewmodel.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/oficial_scaffold.dart';

class ScoringView extends StatefulWidget {
  final bool embedded;

  const ScoringView({super.key, this.embedded = false});

  @override
  State<ScoringView> createState() => _ScoringViewState();
}

class _ScoringViewState extends State<ScoringView> {
  final _fichaidController = TextEditingController();
  final _montoController = TextEditingController();
  final _plazoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _aplicarPrefill());
  }

  void _aplicarPrefill() {
    final pre = context.read<ScoringViewModel>().prefill;
    if (pre == null) return;
    _fichaidController.text = pre.fichaid;
    _montoController.text = pre.monto.toStringAsFixed(0);
    _plazoController.text = pre.plazoMeses.toString();
    context.read<ScoringViewModel>().limpiarPrefill();
  }

  @override
  void dispose() {
    _fichaidController.dispose();
    _montoController.dispose();
    _plazoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ScoringViewModel>();

    return OficialScaffold(
      embedded: widget.embedded,
      title: 'Evaluación de Crédito',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Evaluar crédito de campo',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Ingrese los datos para la evaluación',
                style: TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 24),
            TextField(
              controller: _fichaidController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                  labelText: 'ID de Ficha',
                  prefixIcon: Icon(Icons.assignment_outlined)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _montoController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Monto solicitado (S/)',
                  prefixIcon: Icon(Icons.attach_money)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _plazoController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Plazo (meses)',
                  prefixIcon: Icon(Icons.calendar_today)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: vm.loading
                    ? null
                    : () {
                        final monto = double.tryParse(_montoController.text.trim());
                        final plazo = int.tryParse(_plazoController.text.trim());
                        if (monto == null || plazo == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Ingrese valores válidos'),
                                backgroundColor: Colors.redAccent),
                          );
                          return;
                        }
                        vm.evaluar(
                          fichaid: _fichaidController.text.trim(),
                          monto: monto,
                          plazoMeses: plazo,
                        );
                      },
                child: vm.loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.navy))
                    : const Text('EVALUAR CRÉDITO'),
              ),
            ),
            const SizedBox(height: 24),
            if (vm.error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                    const SizedBox(width: 8),
                    Text(vm.error!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                  ],
                ),
              ),
            if (vm.resultado != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.superficie,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.verdePendiente.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Resultado',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _ResultadoRow(
                        label: 'Score',
                        value: vm.resultado!.score.toStringAsFixed(2)),
                    _ResultadoRow(
                        label: 'Segmento', value: vm.resultado!.segmento),
                    _ResultadoRow(
                        label: 'Decisión', value: vm.resultado!.decision),
                    if (vm.resultado!.montomaximo != null)
                      _ResultadoRow(
                          label: 'Monto Máximo',
                          value: 'S/ ${vm.resultado!.montomaximo!.toStringAsFixed(2)}'),
                    if (vm.resultado!.tasasugerida != null)
                      _ResultadoRow(
                          label: 'Tasa Sugerida',
                          value: '${vm.resultado!.tasasugerida!.toStringAsFixed(2)}%'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultadoRow extends StatelessWidget {
  final String label;
  final String value;
  const _ResultadoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text(value,
              style: const TextStyle(
                  color: AppTheme.amarillo,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
