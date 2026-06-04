import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/sbs_semaforo.dart';
import '../../model/alerta_cartera_model.dart';
import '../../model/cartera_diaria_model.dart';
import '../../model/credito_historial_model.dart';
import '../../model/pago_mensual_model.dart';
import '../../ui/theme/app_theme.dart';
import '../../viewmodel/auth_oficial_viewmodel.dart';
import '../../viewmodel/ficha_cliente_viewmodel.dart';
import '../../viewmodel/scoring_viewmodel.dart';
import 'scoring_view.dart';

/// Argumentos para abrir la ficha completa del cliente (Bloque 3).
class FichaClienteArgs {
  final String? clienteId;
  final String documento;
  final String? nombreFallback;
  final String? telefonoFallback;

  const FichaClienteArgs({
    this.clienteId,
    required this.documento,
    this.nombreFallback,
    this.telefonoFallback,
  });

  factory FichaClienteArgs.fromCartera(CarteraDiariaModel c) {
    return FichaClienteArgs(
      clienteId: c.clienteid,
      documento: c.documento,
      nombreFallback: c.nombrecliente,
      telefonoFallback: c.telefono,
    );
  }
}

class FichaClienteScreen extends StatefulWidget {
  final FichaClienteArgs args;

  const FichaClienteScreen({super.key, required this.args});

  @override
  State<FichaClienteScreen> createState() => _FichaClienteScreenState();
}

class _FichaClienteScreenState extends State<FichaClienteScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _iniciar());
  }

  void _iniciar() {
    final auth = context.read<AuthOficialViewModel>().oficial;
    if (auth == null) return;
    final vm = context.read<FichaClienteViewModel>();
    vm.cargar(
      asesorid: auth.asesorid,
      clienteid: widget.args.clienteId,
      documento: widget.args.documento,
    );
    vm.iniciarRealtime(auth.asesorid);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FichaClienteViewModel>();

    return Scaffold(
      backgroundColor: AppTheme.fondoOscuro,
      appBar: AppBar(
        title: const Text(
          'Ficha del cliente',
          style: TextStyle(
            color: AppTheme.amarillo,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Llamar',
            onPressed: () async {
              final ok = await vm.llamarCliente();
              if (!context.mounted) return;
              if (!ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No se pudo iniciar la llamada')),
                );
              }
            },
            icon: const Icon(Icons.phone),
          ),
        ],
      ),
      body: vm.loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.amarillo),
            )
          : vm.error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      vm.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: AppTheme.amarillo,
                  onRefresh: () async {
                    final auth = context.read<AuthOficialViewModel>().oficial;
                    if (auth == null) return;
                    await vm.cargar(
                      asesorid: auth.asesorid,
                      clienteid: widget.args.clienteId,
                      documento: widget.args.documento,
                    );
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (vm.offline)
                        _BannerOffline(),
                      if (vm.alertasCliente.isNotEmpty)
                        _SeccionAlertas(alertas: vm.alertasCliente),
                      _EncabezadoCliente(
                        vm: vm,
                        fallback: widget.args,
                      ),
                      const SizedBox(height: 16),
                      _SeccionPosicion(posicion: vm.posicion, offline: vm.offline),
                      const SizedBox(height: 16),
                      _IndicadoresPago(vm: vm),
                      const SizedBox(height: 16),
                      _GraficoPagos(pagos: vm.pagos),
                      const SizedBox(height: 16),
                      _HistorialCreditos(creditos: vm.creditos),
                      const SizedBox(height: 16),
                      _OfertaPreaprobada(
                        oferta: vm.oferta,
                        onUsar: () => _usarOferta(context, vm),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  void _usarOferta(BuildContext context, FichaClienteViewModel vm) {
    final oferta = vm.oferta;
    if (oferta == null) return;
    context.read<ScoringViewModel>().aplicarOfertaPreaprobada(
      fichaid: oferta.fichaid,
      monto: oferta.montopreaprobado,
      plazoMeses: oferta.plazomeses,
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScoringView()),
    );
  }
}

class _BannerOffline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.4)),
      ),
      child: const Row(
        children: [
          Icon(Icons.cloud_off, color: Colors.orangeAccent, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Modo offline — datos de la última sincronización',
              style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeccionAlertas extends StatelessWidget {
  final List<AlertaCarteraModel> alertas;
  const _SeccionAlertas({required this.alertas});

  Color _color(String s) {
    switch (s) {
      case 'critical':
        return Colors.redAccent;
      case 'warning':
        return Colors.orangeAccent;
      default:
        return AppTheme.azulVisitado;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Alertas en tiempo real',
          style: TextStyle(
            color: AppTheme.amarillo,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        ...alertas.take(3).map(
              (a) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.superficie,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _color(a.severidad).withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.titulo,
                      style: TextStyle(
                        color: _color(a.severidad),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      a.mensaje,
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _EncabezadoCliente extends StatelessWidget {
  final FichaClienteViewModel vm;
  final FichaClienteArgs fallback;

  const _EncabezadoCliente({required this.vm, required this.fallback});

  @override
  Widget build(BuildContext context) {
    final c = vm.cliente;
    final nombre = c?.nombreCompleto ?? fallback.nombreFallback ?? 'Cliente';
    final doc = c?.documento ?? fallback.documento;
    final sbsColor = SbsSemaforo.color(c?.clasificacionsbs);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: sbsColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: sbsColor.withValues(alpha: 0.2),
            backgroundImage:
                c?.fotourl != null ? NetworkImage(c!.fotourl!) : null,
            child: c?.fotourl == null
                ? Text(
                    c?.iniciales ?? nombre.substring(0, 1),
                    style: TextStyle(
                      color: sbsColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text('DNI $doc', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                if ((c?.direccion ?? '').isNotEmpty)
                  Text(c!.direccion!, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                if ((c?.telefono ?? fallback.telefonoFallback ?? '').isNotEmpty)
                  Text(
                    c?.telefono ?? fallback.telefonoFallback!,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _SbsBadge(clasificacion: c?.clasificacionsbs ?? 'Normal'),
                    const SizedBox(width: 8),
                    Text(
                      '${c?.tiponegocio ?? '—'} · ${c?.antiguedadnegocio ?? 0} meses',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SbsBadge extends StatelessWidget {
  final String clasificacion;
  const _SbsBadge({required this.clasificacion});

  @override
  Widget build(BuildContext context) {
    final color = SbsSemaforo.color(clasificacion);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        'SBS ${SbsSemaforo.etiqueta(clasificacion)}',
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _SeccionPosicion extends StatelessWidget {
  final dynamic posicion;
  final bool offline;

  const _SeccionPosicion({required this.posicion, required this.offline});

  @override
  Widget build(BuildContext context) {
    if (posicion == null) {
      return const SizedBox.shrink();
    }
    return _CardSeccion(
      titulo: 'Posición en el sistema',
      subtitulo: offline || posicion.desdeCache == true
          ? 'Datos en caché / última consulta'
          : 'Edge Function consulta-posicion',
      child: Column(
        children: [
          _FilaMetrica('Deuda total', 'S/ ${posicion.deudaTotal.toStringAsFixed(0)}'),
          _FilaMetrica('Cuentas vigentes', '${posicion.cuentasVigentes}'),
          _FilaMetrica('Cuentas en mora', '${posicion.cuentasEnMora}'),
          _FilaMetrica('Días mayor mora', '${posicion.diasMayorMora}'),
          _FilaMetrica(
            'Último pago',
            posicion.fechaUltimoPago ?? '—',
          ),
        ],
      ),
    );
  }
}

class _IndicadoresPago extends StatelessWidget {
  final FichaClienteViewModel vm;
  const _IndicadoresPago({required this.vm});

  @override
  Widget build(BuildContext context) {
    return _CardSeccion(
      titulo: 'Indicadores de comportamiento',
      child: Row(
        children: [
          Expanded(
            child: _MiniKpi(
              label: '% puntual',
              value: '${vm.porcentajePuntual.toStringAsFixed(0)}%',
            ),
          ),
          Expanded(
            child: _MiniKpi(
              label: 'Días prom. mora',
              value: vm.diasPromedioMora.toStringAsFixed(0),
            ),
          ),
          Expanded(
            child: _MiniKpi(
              label: 'Total pagado',
              value: 'S/ ${vm.montoTotalPagado.toStringAsFixed(0)}',
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniKpi extends StatelessWidget {
  final String label;
  final String value;
  const _MiniKpi({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.amarillo,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }
}

class _GraficoPagos extends StatelessWidget {
  final List<PagoMensualModel> pagos;
  const _GraficoPagos({required this.pagos});

  Color _colorBarra(PagoMensualModel p) {
    if (p.esPuntual) return const Color(0xFF43A047);
    if (p.esMora) return const Color(0xFFE53935);
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    if (pagos.isEmpty) {
      return _CardSeccion(
        titulo: 'Historial de pagos (12 meses)',
        child: const Text(
          'Sin datos de pagos',
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
      );
    }

    final maxY = pagos
            .map((p) => p.montopagado)
            .fold(0.0, (a, b) => a > b ? a : b) +
        200;

    return _CardSeccion(
      titulo: 'Historial de pagos (12 meses)',
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= pagos.length) return const SizedBox.shrink();
                        final parts = pagos[i].periodo.split('-');
                        final mes = parts.length > 1 ? parts[1] : '';
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            mes,
                            style: const TextStyle(color: Colors.white38, fontSize: 9),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < pagos.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: pagos[i].esSinCuota ? maxY * 0.08 : pagos[i].montopagado,
                          color: _colorBarra(pagos[i]),
                          width: 12,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Leyenda(color: Color(0xFF43A047), texto: 'Puntual'),
              SizedBox(width: 12),
              _Leyenda(color: Color(0xFFE53935), texto: 'Mora'),
              SizedBox(width: 12),
              _Leyenda(color: Colors.grey, texto: 'Sin cuota'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Leyenda extends StatelessWidget {
  final Color color;
  final String texto;
  const _Leyenda({required this.color, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 4),
        Text(texto, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }
}

class _HistorialCreditos extends StatelessWidget {
  final List<CreditoHistorialModel> creditos;
  const _HistorialCreditos({required this.creditos});

  @override
  Widget build(BuildContext context) {
    return _CardSeccion(
      titulo: 'Últimos créditos',
      child: creditos.isEmpty
          ? const Text('Sin historial', style: TextStyle(color: Colors.white38, fontSize: 12))
          : Column(
              children: creditos
                  .map(
                    (cr) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cr.numerocredito,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'S/ ${cr.monto.toStringAsFixed(0)} · ${cr.plazomeses}m · TEA ${cr.tea.toStringAsFixed(1)}%',
                                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            cr.estado.toUpperCase(),
                            style: TextStyle(
                              color: cr.estado == 'moroso'
                                  ? Colors.redAccent
                                  : AppTheme.verdePendiente,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _OfertaPreaprobada extends StatelessWidget {
  final dynamic oferta;
  final VoidCallback onUsar;

  const _OfertaPreaprobada({required this.oferta, required this.onUsar});

  @override
  Widget build(BuildContext context) {
    if (oferta == null) {
      return _CardSeccion(
        titulo: 'Oferta preaprobada',
        child: const Text(
          'Sin oferta vigente para este cliente',
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
      );
    }

    final confianza = oferta.scoreaprobacion.clamp(0, 100) / 100.0;

    return _CardSeccion(
      titulo: 'Oferta preaprobada',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FilaMetrica('Monto', 'S/ ${oferta.montopreaprobado.toStringAsFixed(0)}'),
          _FilaMetrica('Plazo', '${oferta.plazomeses} meses'),
          _FilaMetrica('TEA', '${oferta.tea.toStringAsFixed(1)}%'),
          const SizedBox(height: 8),
          const Text('Confianza', style: TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: confianza,
              minHeight: 8,
              backgroundColor: Colors.white12,
              color: AppTheme.amarillo,
            ),
          ),
          Text(
            '${oferta.scoreaprobacion.toStringAsFixed(0)}% score',
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: onUsar,
            child: const Text('USAR ESTA OFERTA'),
          ),
        ],
      ),
    );
  }
}

class _CardSeccion extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final Widget child;

  const _CardSeccion({
    required this.titulo,
    this.subtitulo,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.amarillo.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: AppTheme.amarillo,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          if (subtitulo != null) ...[
            const SizedBox(height: 2),
            Text(subtitulo!, style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _FilaMetrica extends StatelessWidget {
  final String label;
  final String value;
  const _FilaMetrica(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
