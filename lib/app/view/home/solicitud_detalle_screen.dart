import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/estado_solicitud.dart';
import '../../ui/theme/app_theme.dart';
import '../../viewmodel/auth_oficial_viewmodel.dart';
import '../../viewmodel/solicitud_detalle_viewmodel.dart';

class SolicitudDetalleScreen extends StatefulWidget {
  final String solicitudId;

  const SolicitudDetalleScreen({super.key, required this.solicitudId});

  @override
  State<SolicitudDetalleScreen> createState() => _SolicitudDetalleScreenState();
}

class _SolicitudDetalleScreenState extends State<SolicitudDetalleScreen> {
  final _notaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  void _cargar() {
    final auth = context.read<AuthOficialViewModel>().oficial;
    if (auth == null) return;
    context.read<SolicitudDetalleViewModel>().cargar(
          solicitudId: widget.solicitudId,
          asesorId: auth.asesorid,
          autorNombre: '${auth.nombre} ${auth.apellido}'.trim(),
          perfil: auth.perfil,
        );
  }

  @override
  void dispose() {
    _notaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SolicitudDetalleViewModel>();
    final d = vm.detalle;

    return Scaffold(
      backgroundColor: AppTheme.fondoOscuro,
      appBar: AppBar(
        title: const Text(
          'Detalle solicitud',
          style: TextStyle(
            color: AppTheme.amarillo,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        actions: [
          if (d != null)
            IconButton(
              onPressed: vm.generandoPdf ? null : () => vm.compartirPdf(),
              icon: vm.generandoPdf
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.share, color: AppTheme.amarillo),
              tooltip: 'Compartir PDF (WhatsApp, etc.)',
            ),
        ],
      ),
      body: vm.cargando
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.amarillo),
            )
          : d == null
              ? const Center(
                  child: Text(
                    'No se encontró la solicitud',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        d.nombreCliente,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        d.numeroExpediente ?? 'Sin expediente',
                        style: const TextStyle(
                          color: AppTheme.amarillo,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _InfoRow('Estado', d.estado?.etiqueta ?? '—',
                          color: d.estado?.color),
                      _InfoRow('Monto', 'S/ ${d.monto.toStringAsFixed(0)}'),
                      _InfoRow('DNI', d.dni),
                      _InfoRow(
                        'Analista',
                        d.analistaAsignado ?? 'Por asignar',
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Línea de tiempo',
                        style: TextStyle(
                          color: AppTheme.amarillo,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...vm.lineaTiempo.map((e) => _EtapaTimeline(etapa: e)),
                      const SizedBox(height: 24),
                      const Text(
                        'Notas internas',
                        style: TextStyle(
                          color: AppTheme.amarillo,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (vm.puedeAgregarNota) ...[
                        TextField(
                          controller: _notaController,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Agregar nota (solo asesor/supervisor)',
                            hintStyle: TextStyle(color: Colors.white38),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final ok = await vm.agregarNota(
                              _notaController.text,
                            );
                            if (!context.mounted) return;
                            if (ok) {
                              _notaController.clear();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Nota guardada')),
                              );
                            }
                          },
                          child: const Text('GUARDAR NOTA'),
                        ),
                        const SizedBox(height: 12),
                      ],
                      ...vm.notas.map(
                        (n) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${n.autorNombre} · ${n.perfilAutor}',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                n.contenido,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (vm.notas.isEmpty)
                        const Text(
                          'Sin notas internas',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String valor;
  final Color? color;

  const _InfoRow(this.label, this.valor, {this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          Text(
            valor,
            style: TextStyle(
              color: color ?? Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _EtapaTimeline extends StatelessWidget {
  final EtapaLineaTiempo etapa;

  const _EtapaTimeline({required this.etapa});

  @override
  Widget build(BuildContext context) {
    final completada = etapa.completada;
    final futura = etapa.futura;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: completada
                    ? AppTheme.verdePendiente
                    : Colors.transparent,
                border: Border.all(
                  color: completada
                      ? AppTheme.verdePendiente
                      : futura
                          ? Colors.white24
                          : AppTheme.amarillo,
                  width: futura ? 1.5 : 2,
                  style: futura ? BorderStyle.solid : BorderStyle.solid,
                ),
              ),
            ),
            if (!futura || completada)
              Container(width: 2, height: 28, color: AppTheme.verdePendiente)
            else
              Container(
                width: 2,
                height: 28,
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: Colors.white24,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                ),
                child: CustomPaint(
                  painter: _DottedLinePainter(),
                  size: const Size(2, 28),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etapa.titulo,
                  style: TextStyle(
                    color: futura && !completada
                        ? Colors.white38
                        : Colors.white,
                    fontWeight:
                        completada ? FontWeight.bold : FontWeight.normal,
                    decoration: futura && !completada
                        ? TextDecoration.none
                        : null,
                  ),
                ),
                if (etapa.fecha != null)
                  Text(
                    '${etapa.fecha!.day}/${etapa.fecha!.month}/${etapa.fecha!.year}',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 2;
    const dash = 4.0;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(0, y + dash / 2), paint);
      y += dash;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
