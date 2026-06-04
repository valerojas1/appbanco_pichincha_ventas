import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/asesor_id_util.dart';
import '../../core/cartera_mora_semaforo.dart';
import '../../model/cartera_vencida_model.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/oficial_scaffold.dart';
import '../../viewmodel/auth_oficial_viewmodel.dart';
import '../../viewmodel/cartera_vencida_viewmodel.dart';
import 'accion_cobranza_screen.dart';

class CarteraVencidaScreen extends StatefulWidget {
  final bool embedded;

  const CarteraVencidaScreen({super.key, this.embedded = false});

  @override
  State<CarteraVencidaScreen> createState() => _CarteraVencidaScreenState();
}

class _CarteraVencidaScreenState extends State<CarteraVencidaScreen> {
  final _busquedaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _busquedaController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final oficial = context.read<AuthOficialViewModel>().oficial;
      if (oficial != null) {
        context
            .read<CarteraVencidaViewModel>()
            .iniciar(AsesorIdUtil.idsConsulta(oficial));
      }
    });
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CarteraVencidaViewModel>();

    return OficialScaffold(
      embedded: widget.embedded,
      title: 'Cartera vencida',
      body: vm.cargando && vm.lista.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.amarillo),
            )
          : Column(
              children: [
                if (vm.error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      vm.error!,
                      style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
                    ),
                  ),
                _EncabezadoMontoTotal(monto: vm.montoTotal, cantidad: vm.lista.length),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    controller: _busquedaController,
                    onChanged: vm.setBusqueda,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre, DNI o crédito',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _busquedaController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _busquedaController.clear();
                                vm.setBusqueda('');
                              },
                            )
                          : null,
                      isDense: true,
                    ),
                  ),
                ),
                Expanded(
                  child: vm.listaFiltrada.isEmpty
                      ? const Center(
                          child: Text(
                            'Sin clientes en mora para este asesor',
                            style: TextStyle(color: Colors.white54),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: vm.refrescar,
                          color: AppTheme.amarillo,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: vm.listaFiltrada.length,
                            itemBuilder: (context, i) => _TarjetaMora(
                              item: vm.listaFiltrada[i],
                              onTap: () => _abrirAccion(context, vm.listaFiltrada[i]),
                            ),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Future<void> _abrirAccion(BuildContext context, CarteraVencidaModel item) async {
    final actualizado = await Navigator.push<CarteraVencidaModel>(
      context,
      MaterialPageRoute(
        builder: (_) => AccionCobranzaScreen(cartera: item),
      ),
    );
    if (actualizado != null && context.mounted) {
      context.read<CarteraVencidaViewModel>().actualizarItemLocal(actualizado);
    }
  }
}

class _EncabezadoMontoTotal extends StatelessWidget {
  final double monto;
  final int cantidad;

  const _EncabezadoMontoTotal({required this.monto, required this.cantidad});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.amarillo.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monto total vencido',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            'S/ ${monto.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppTheme.amarillo,
              fontWeight: FontWeight.bold,
              fontSize: 26,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$cantidad cliente${cantidad == 1 ? '' : 's'} en mora',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _TarjetaMora extends StatelessWidget {
  final CarteraVencidaModel item;
  final VoidCallback onTap;

  const _TarjetaMora({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = CarteraMoraSemaforo.color(item.diasMora);

    return Card(
      color: AppTheme.superficie,
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 56,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.nombreCliente,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'DNI ${item.dni} · ${item.numeroCredito}',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      CarteraMoraSemaforo.etiqueta(item.diasMora),
                      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'S/ ${item.saldoVencido.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppTheme.amarillo,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(Icons.chevron_right, color: Colors.white38, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
