import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/amortizacion_francesa.dart';
import '../../../core/formato_fecha.dart';
import '../../../model/cronograma_cuota_model.dart';
import '../../../model/estado_solicitud.dart';
import '../../../model/solicitud_resumen_model.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../viewmodel/admin_revision_documentos_viewmodel.dart';
import '../../../viewmodel/admin_solicitud_evaluacion_viewmodel.dart';
import '../../../viewmodel/admin_solicitudes_tablero_viewmodel.dart';
import '../../../viewmodel/admin_web_inicio_viewmodel.dart';
import '../../../viewmodel/auth_oficial_viewmodel.dart';
import '../../../viewmodel/solicitud_detalle_viewmodel.dart';
import '../../home/visor_documento_screen.dart';
import 'admin_detalle_documentos_panel.dart';

/// Evaluación completa de una solicitud: datos, documentos y acciones de comité.
class AdminSolicitudEvaluacionScreen extends StatefulWidget {
  final String solicitudId;

  const AdminSolicitudEvaluacionScreen({
    super.key,
    required this.solicitudId,
  });

  @override
  State<AdminSolicitudEvaluacionScreen> createState() =>
      _AdminSolicitudEvaluacionScreenState();
}

class _AdminSolicitudEvaluacionScreenState
    extends State<AdminSolicitudEvaluacionScreen> {
  final _notaController = TextEditingController();
  bool _huboCambio = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  void _cargar() {
    final auth = context.read<AuthOficialViewModel>().oficial;
    if (auth == null) return;
    context.read<AdminSolicitudEvaluacionViewModel>().cargar(
          solicitudId: widget.solicitudId,
          asesorId: auth.asesorid,
          autorNombre: '${auth.nombre} ${auth.apellido}'.trim(),
        );
  }

  Future<void> _refrescarPaneles() async {
    if (!mounted) return;
    await Future.wait([
      context.read<AdminSolicitudesTableroViewModel>().refrescar(),
      context.read<AdminRevisionDocumentosViewModel>().cargarLista(),
      context.read<AdminWebInicioViewModel>().cargar(),
    ]);
  }

  Future<void> _confirmar({
    required String titulo,
    required String mensaje,
    required Future<String?> Function() accion,
    required String exito,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.superficie,
        title: Text(titulo, style: const TextStyle(color: Colors.white)),
        content: Text(mensaje, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final error = await accion();
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
      );
      return;
    }

    _huboCambio = true;
    await _refrescarPaneles();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(exito)));
  }

  Future<void> _rechazar() async {
    final motivoCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.superficie,
        title: const Text(
          'Rechazar solicitud',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: motivoCtrl,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Motivo del rechazo (obligatorio)',
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final vm = context.read<AdminSolicitudEvaluacionViewModel>();
    final error = await vm.rechazar(motivoCtrl.text);
    motivoCtrl.dispose();
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
      );
      return;
    }

    _huboCambio = true;
    await _refrescarPaneles();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Solicitud rechazada')),
    );
  }

  Future<void> _aprobar() async {
    final vm = context.read<AdminSolicitudEvaluacionViewModel>();
    final d = vm.detalle;
    if (d == null) return;

    final montoCtrl = TextEditingController(text: d.monto.toStringAsFixed(0));
    final cuotaCtrl = TextEditingController(
      text: AmortizacionFrancesa.calcularCuota(
        monto: d.monto,
        teaPorcentaje: d.tea,
        plazoMeses: d.plazoMeses,
      ).toStringAsFixed(2),
    );
    int diaPago = d.diaPago ?? DateTime.now().day.clamp(1, 28);

    void recalcularCuota(StateSetter setSt) {
      final monto = double.tryParse(montoCtrl.text.trim()) ?? d.monto;
      final cuota = AmortizacionFrancesa.calcularCuota(
        monto: monto,
        teaPorcentaje: d.tea,
        plazoMeses: d.plazoMeses,
      );
      cuotaCtrl.text = cuota.toStringAsFixed(2);
      setSt(() {});
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: AppTheme.superficie,
          title: const Text(
            'Aprobar crédito',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${d.nombreCliente} · ${d.plazoMeses} meses · TEA ${d.tea.toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: montoCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Monto aprobado (S/)',
                    labelStyle: const TextStyle(color: Colors.white54),
                    helperText:
                        'Solicitado: S/ ${d.monto.toStringAsFixed(0)}',
                    helperStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                  onChanged: (_) => recalcularCuota(setSt),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cuotaCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Cuota mensual fijada (S/)',
                    labelStyle: TextStyle(color: Colors.white54),
                    helperText: 'Calculada por amortización francesa; puede ajustarse.',
                    helperStyle: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: diaPago,
                  dropdownColor: AppTheme.superficie,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Día de pago mensual',
                    labelStyle: TextStyle(color: Colors.white54),
                    helperText: 'Día del mes en que vencerá cada cuota.',
                    helperStyle: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                  items: List.generate(
                    28,
                    (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text('Día ${i + 1} de cada mes'),
                    ),
                  ),
                  onChanged: (v) => setSt(() => diaPago = v ?? diaPago),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.verdePendiente,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Aprobar'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) {
      montoCtrl.dispose();
      cuotaCtrl.dispose();
      return;
    }

    final monto = double.tryParse(montoCtrl.text.trim()) ?? 0;
    final cuota = double.tryParse(cuotaCtrl.text.trim()) ?? 0;
    montoCtrl.dispose();
    cuotaCtrl.dispose();

    final error = await vm.aprobar(
      montoAprobado: monto,
      cuotaMensual: cuota,
      diaPago: diaPago,
    );
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
      );
      return;
    }

    _huboCambio = true;
    await _refrescarPaneles();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Crédito aprobado')),
    );
  }

  Future<void> _desembolsar() async {
    final vm = context.read<AdminSolicitudEvaluacionViewModel>();
    final d = vm.detalle;
    if (d == null) return;

    var fechaDesembolso = DateTime.now();
    int diaPago = d.diaPago ?? fechaDesembolso.day.clamp(1, 28);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: AppTheme.superficie,
          title: const Text(
            'Registrar desembolso',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cuota fijada: S/ ${(d.cuotaMensual ?? 0).toStringAsFixed(2)} · '
                'Monto: S/ ${d.montoEfectivo.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Fecha de desembolso',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                subtitle: Text(
                  FormatoFecha.corta(fechaDesembolso),
                  style: const TextStyle(
                    color: AppTheme.amarillo,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_month, color: AppTheme.amarillo),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: fechaDesembolso,
                      firstDate: d.fechaAprobacion ?? DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setSt(() => fechaDesembolso = picked);
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: diaPago,
                dropdownColor: AppTheme.superficie,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Día de pago de cuotas',
                  labelStyle: TextStyle(color: Colors.white54),
                ),
                items: List.generate(
                  28,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text('Día ${i + 1} de cada mes'),
                  ),
                ),
                onChanged: (v) => setSt(() => diaPago = v ?? diaPago),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightGreenAccent,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Registrar desembolso'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;

    final error = await vm.registrarDesembolso(
      fechaDesembolso: fechaDesembolso,
      diaPago: diaPago,
    );
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
      );
      return;
    }

    _huboCambio = true;
    await _refrescarPaneles();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Desembolso registrado')),
    );
  }

  Future<void> _condicionar() async {
    final vm = context.read<AdminSolicitudEvaluacionViewModel>();
    final d = vm.detalle;
    if (d == null) return;

    String codigo = '25';
    final montoCtrl = TextEditingController(
      text: (d.monto * 0.8).toStringAsFixed(0),
    );
    final motivoCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: AppTheme.superficie,
          title: const Text(
            'Condicionar crédito',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: codigo,
                  dropdownColor: AppTheme.superficie,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Caso condicionado',
                    labelStyle: TextStyle(color: Colors.white54),
                  ),
                  items: CasoCondicionado.catalogo
                      .map((c) => DropdownMenuItem(
                            value: c.codigo,
                            child: Text(c.titulo, style: const TextStyle(fontSize: 12)),
                          ))
                      .toList(),
                  onChanged: (v) => setSt(() => codigo = v ?? '25'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: montoCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText:
                        'Monto aprobado (solicitado: S/ ${d.monto.toStringAsFixed(0)})',
                    labelStyle: const TextStyle(color: Colors.white54),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: motivoCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Motivo de condición',
                    labelStyle: TextStyle(color: Colors.white54),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Condicionar'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;

    final monto = double.tryParse(montoCtrl.text.trim()) ?? 0;
    final error = await vm.condicionar(
      codigoCondicion: codigo,
      montoAprobado: monto,
      motivo: motivoCtrl.text,
    );
    montoCtrl.dispose();
    motivoCtrl.dispose();
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
      );
      return;
    }

    _huboCambio = true;
    await _refrescarPaneles();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Solicitud condicionada')),
    );
  }

  @override
  void dispose() {
    _notaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminSolicitudEvaluacionViewModel>();
    final d = vm.detalle;
    final ancho = MediaQuery.sizeOf(context).width;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && _huboCambio) _refrescarPaneles();
      },
      child: Scaffold(
        backgroundColor: AppTheme.fondoOscuro,
        appBar: AppBar(
          title: const Text(
            'Evaluar solicitud',
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
                    : const Icon(Icons.picture_as_pdf, color: AppTheme.amarillo),
                tooltip: 'Exportar PDF',
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
                : ancho > 960
                    ? _LayoutAncho(
                        vm: vm,
                        d: d,
                        notaController: _notaController,
                        onRecibirComite: () => _confirmar(
                          titulo: 'Recibir en comité',
                          mensaje:
                              'La solicitud pasará a evaluación de comité. '
                              'Se notificará al asesor.',
                          accion: vm.recibirEnComite,
                          exito: 'Solicitud recibida en comité',
                        ),
                        onIniciarEvaluacion: () => _confirmar(
                          titulo: 'Iniciar evaluación',
                          mensaje:
                              'La solicitud pasará a estado en evaluación.',
                          accion: vm.iniciarEvaluacion,
                          exito: 'Evaluación iniciada',
                        ),
                        onAprobar: _aprobar,
                        onRechazar: _rechazar,
                        onCondicionar: _condicionar,
                        onDesembolsar: _desembolsar,
                        onVerDocumento: _verDocumento,
                      )
                    : _LayoutMovil(
                        vm: vm,
                        d: d,
                        notaController: _notaController,
                        onRecibirComite: () => _confirmar(
                          titulo: 'Recibir en comité',
                          mensaje:
                              'La solicitud pasará a evaluación de comité.',
                          accion: vm.recibirEnComite,
                          exito: 'Solicitud recibida en comité',
                        ),
                        onIniciarEvaluacion: () => _confirmar(
                          titulo: 'Iniciar evaluación',
                          mensaje:
                              'La solicitud pasará a estado en evaluación.',
                          accion: vm.iniciarEvaluacion,
                          exito: 'Evaluación iniciada',
                        ),
                        onAprobar: _aprobar,
                        onRechazar: _rechazar,
                        onCondicionar: _condicionar,
                        onDesembolsar: _desembolsar,
                        onVerDocumento: _verDocumento,
                      ),
      ),
    );
  }

  void _verDocumento(String titulo, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VisorDocumentoScreen(titulo: titulo, imageUrl: url),
      ),
    );
  }
}

class _LayoutAncho extends StatelessWidget {
  final AdminSolicitudEvaluacionViewModel vm;
  final SolicitudDetalleModel d;
  final TextEditingController notaController;
  final VoidCallback onRecibirComite;
  final VoidCallback onIniciarEvaluacion;
  final VoidCallback onAprobar;
  final VoidCallback onRechazar;
  final VoidCallback onCondicionar;
  final VoidCallback onDesembolsar;
  final void Function(String titulo, String url) onVerDocumento;

  const _LayoutAncho({
    required this.vm,
    required this.d,
    required this.notaController,
    required this.onRecibirComite,
    required this.onIniciarEvaluacion,
    required this.onAprobar,
    required this.onRechazar,
    required this.onCondicionar,
    required this.onDesembolsar,
    required this.onVerDocumento,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _EncabezadoSolicitud(detalle: d),
                const SizedBox(height: 16),
                _DatosSolicitud(detalle: d),
                if (vm.firmaBytes != null) ...[
                  const SizedBox(height: 16),
                  _FirmaCliente(bytes: vm.firmaBytes!),
                ],
                const SizedBox(height: 16),
                _SeccionTimeline(lineaTiempo: vm.lineaTiempo),
                if (vm.muestraCronograma && vm.cronograma.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _CronogramaCuotas(
                    cronograma: vm.cronograma,
                    monto: d.montoEfectivo,
                    cuota: d.cuotaMensual ?? 0,
                  ),
                ],
                const SizedBox(height: 16),
                _SeccionNotas(
                  notas: vm.notas,
                  controller: notaController,
                  onGuardar: () async {
                    final ok = await vm.agregarNota(notaController.text);
                    if (!context.mounted) return;
                    if (ok) {
                      notaController.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nota guardada')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        const VerticalDivider(width: 1, color: Colors.white12),
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: AdminDetalleDocumentosPanel(
                  solicitudId: d.id,
                  slots: vm.slots,
                  cargando: false,
                  onVerDocumento: onVerDocumento,
                ),
              ),
              _PanelAcciones(
                vm: vm,
                onRecibirComite: onRecibirComite,
                onIniciarEvaluacion: onIniciarEvaluacion,
                onAprobar: onAprobar,
                onRechazar: onRechazar,
                onCondicionar: onCondicionar,
                onDesembolsar: onDesembolsar,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LayoutMovil extends StatelessWidget {
  final AdminSolicitudEvaluacionViewModel vm;
  final SolicitudDetalleModel d;
  final TextEditingController notaController;
  final VoidCallback onRecibirComite;
  final VoidCallback onIniciarEvaluacion;
  final VoidCallback onAprobar;
  final VoidCallback onRechazar;
  final VoidCallback onCondicionar;
  final VoidCallback onDesembolsar;
  final void Function(String titulo, String url) onVerDocumento;

  const _LayoutMovil({
    required this.vm,
    required this.d,
    required this.notaController,
    required this.onRecibirComite,
    required this.onIniciarEvaluacion,
    required this.onAprobar,
    required this.onRechazar,
    required this.onCondicionar,
    required this.onDesembolsar,
    required this.onVerDocumento,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _EncabezadoSolicitud(detalle: d),
          const SizedBox(height: 16),
          _PanelAcciones(
            vm: vm,
            onRecibirComite: onRecibirComite,
            onIniciarEvaluacion: onIniciarEvaluacion,
            onAprobar: onAprobar,
            onRechazar: onRechazar,
            onCondicionar: onCondicionar,
            onDesembolsar: onDesembolsar,
          ),
          const SizedBox(height: 16),
          _DatosSolicitud(detalle: d),
          if (vm.firmaBytes != null) ...[
            const SizedBox(height: 16),
            _FirmaCliente(bytes: vm.firmaBytes!),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 420,
            child: AdminDetalleDocumentosPanel(
              solicitudId: d.id,
              slots: vm.slots,
              cargando: false,
              onVerDocumento: onVerDocumento,
            ),
          ),
          const SizedBox(height: 16),
          _SeccionTimeline(lineaTiempo: vm.lineaTiempo),
          if (vm.muestraCronograma && vm.cronograma.isNotEmpty) ...[
            const SizedBox(height: 16),
            _CronogramaCuotas(
              cronograma: vm.cronograma,
              monto: d.montoEfectivo,
              cuota: d.cuotaMensual ?? 0,
            ),
          ],
          const SizedBox(height: 16),
          _SeccionNotas(
            notas: vm.notas,
            controller: notaController,
            onGuardar: () async {
              final ok = await vm.agregarNota(notaController.text);
              if (!context.mounted) return;
              if (ok) {
                notaController.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nota guardada')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _EncabezadoSolicitud extends StatelessWidget {
  final SolicitudDetalleModel detalle;

  const _EncabezadoSolicitud({required this.detalle});

  @override
  Widget build(BuildContext context) {
    final estado = detalle.estado as EstadoSolicitud?;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detalle.nombreCliente,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detalle.numeroExpediente ?? 'Sin expediente',
                  style: const TextStyle(color: AppTheme.amarillo, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (estado?.color ?? Colors.grey).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (estado?.color ?? Colors.grey).withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              estado?.etiqueta ?? '—',
              style: TextStyle(
                color: estado?.color ?? Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DatosSolicitud extends StatelessWidget {
  final SolicitudDetalleModel detalle;

  const _DatosSolicitud({required this.detalle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Datos del crédito',
            style: TextStyle(
              color: AppTheme.amarillo,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          _FilaDato('Monto solicitado', 'S/ ${detalle.monto.toStringAsFixed(0)}'),
          if (detalle.montoAprobado != null)
            _FilaDato(
              'Monto aprobado',
              'S/ ${detalle.montoAprobado!.toStringAsFixed(0)}',
            ),
          if (detalle.codigoCondicion != null) ...[
            _FilaDato(
              'Caso condición',
              CasoCondicionado.porCodigo(detalle.codigoCondicion)?.titulo ??
                  'Caso ${detalle.codigoCondicion}',
            ),
            if (detalle.motivoCondicion != null)
              _FilaDato('Motivo condición', detalle.motivoCondicion!),
          ],
          _FilaDato('Plazo', '${detalle.plazoMeses} meses'),
          if (detalle.cuotaMensual != null)
            _FilaDato(
              'Cuota mensual',
              'S/ ${detalle.cuotaMensual!.toStringAsFixed(2)}',
            ),
          if (detalle.diaPago != null)
            _FilaDato(
              'Día de pago',
              'Día ${detalle.diaPago} de cada mes',
            ),
          if (detalle.fechaDesembolso != null)
            _FilaDato(
              'Fecha desembolso',
              FormatoFecha.corta(detalle.fechaDesembolso),
            ),
          _FilaDato('DNI', detalle.dni),
          if (detalle.telefono != null && detalle.telefono!.isNotEmpty)
            _FilaDato('Teléfono', detalle.telefono!),
          _FilaDato(
            'Analista',
            detalle.analistaAsignado ?? 'Por asignar',
          ),
          if (detalle.motivoRechazo != null)
            _FilaDato('Motivo rechazo', detalle.motivoRechazo!),
          _FilaDato(
            'Declaración jurada',
            detalle.declaracionJurada ? 'Aceptada' : 'Pendiente',
          ),
        ],
      ),
    );
  }
}

class _FilaDato extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _FilaDato(this.etiqueta, this.valor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              etiqueta,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FirmaCliente extends StatelessWidget {
  final Uint8List bytes;

  const _FirmaCliente({required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Firma del cliente',
            style: TextStyle(
              color: AppTheme.amarillo,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: Image.memory(bytes, fit: BoxFit.contain),
          ),
        ],
      ),
    );
  }
}

class _PanelAcciones extends StatelessWidget {
  final AdminSolicitudEvaluacionViewModel vm;
  final VoidCallback onRecibirComite;
  final VoidCallback onIniciarEvaluacion;
  final VoidCallback onAprobar;
  final VoidCallback onRechazar;
  final VoidCallback onCondicionar;
  final VoidCallback onDesembolsar;

  const _PanelAcciones({
    required this.vm,
    required this.onRecibirComite,
    required this.onIniciarEvaluacion,
    required this.onAprobar,
    required this.onRechazar,
    required this.onCondicionar,
    required this.onDesembolsar,
  });

  @override
  Widget build(BuildContext context) {
    if (vm.esTerminal) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: AppTheme.navyOscuro,
        child: Text(
          vm.detalle?.estado == EstadoSolicitud.rechazada
              ? 'Esta solicitud fue rechazada. No hay más acciones disponibles.'
              : 'Crédito desembolsado. Proceso finalizado.',
          style: const TextStyle(color: Colors.white54, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.navyOscuro,
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Acciones de evaluación',
            style: TextStyle(
              color: AppTheme.amarillo,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          if (!vm.docsCompletos &&
              vm.detalle?.estado == EstadoSolicitud.enviada)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Faltan documentos obligatorios. Revise el expediente antes de continuar.',
                style: TextStyle(color: AppTheme.naranjaNuevo, fontSize: 11),
              ),
            ),
          if (vm.procesando)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(color: AppTheme.amarillo),
              ),
            )
          else ...[
            if (vm.puedeIniciarEvaluacion)
              _BotonAccion(
                etiqueta: 'INICIAR EVALUACIÓN',
                icono: Icons.rate_review_outlined,
                color: Colors.deepPurpleAccent,
                onPressed: onIniciarEvaluacion,
              ),
            if (vm.puedeRecibirEnComite)
              _BotonAccion(
                etiqueta: 'RECIBIR EN COMITÉ',
                icono: Icons.inbox_outlined,
                color: AppTheme.azulVisitado,
                onPressed: onRecibirComite,
              ),
            if (vm.puedeAprobar)
              _BotonAccion(
                etiqueta: 'APROBAR CRÉDITO',
                icono: Icons.check_circle_outline,
                color: AppTheme.verdePendiente,
                onPressed: onAprobar,
              ),
            if (vm.puedeCondicionar)
              _BotonAccion(
                etiqueta: 'CONDICIONAR — Casos 25, 26 o 27',
                icono: Icons.tune_outlined,
                color: Colors.amberAccent,
                onPressed: onCondicionar,
              ),
            if (vm.puedeDesembolsar)
              _BotonAccion(
                etiqueta: 'REGISTRAR DESEMBOLSO',
                icono: Icons.payments_outlined,
                color: Colors.lightGreenAccent,
                onPressed: onDesembolsar,
              ),
            if (vm.puedeRechazar)
              _BotonAccion(
                etiqueta: 'RECHAZAR',
                icono: Icons.cancel_outlined,
                color: Colors.redAccent,
                outlined: true,
                onPressed: onRechazar,
              ),
            if (!vm.puedeIniciarEvaluacion &&
                !vm.puedeRecibirEnComite &&
                !vm.puedeAprobar &&
                !vm.puedeCondicionar &&
                !vm.puedeDesembolsar &&
                !vm.puedeRechazar)
              const Text(
                'No hay acciones disponibles para el estado actual.',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
          ],
        ],
      ),
    );
  }
}

class _BotonAccion extends StatelessWidget {
  final String etiqueta;
  final IconData icono;
  final Color color;
  final VoidCallback onPressed;
  final bool outlined;

  const _BotonAccion({
    required this.etiqueta,
    required this.icono,
    required this.color,
    required this.onPressed,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: outlined
          ? OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icono, color: color),
              label: Text(etiqueta),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color.withValues(alpha: 0.6)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            )
          : ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icono),
              label: Text(etiqueta),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: AppTheme.navyOscuro,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
    );
  }
}

class _SeccionTimeline extends StatelessWidget {
  final List<EtapaLineaTiempo> lineaTiempo;

  const _SeccionTimeline({required this.lineaTiempo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Línea de tiempo',
            style: TextStyle(
              color: AppTheme.amarillo,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...lineaTiempo.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    e.completada ? Icons.check_circle : Icons.radio_button_off,
                    size: 16,
                    color: e.completada
                        ? AppTheme.verdePendiente
                        : Colors.white24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e.titulo,
                      style: TextStyle(
                        color: e.completada ? Colors.white : Colors.white38,
                        fontWeight:
                            e.completada ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (e.fecha != null)
                    Text(
                      FormatoFecha.corta(e.fecha),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeccionNotas extends StatelessWidget {
  final List notas;
  final TextEditingController controller;
  final VoidCallback onGuardar;

  const _SeccionNotas({
    required this.notas,
    required this.controller,
    required this.onGuardar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notas de evaluación',
            style: TextStyle(
              color: AppTheme.amarillo,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Agregar observación de comité…',
              hintStyle: TextStyle(color: Colors.white38),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: onGuardar, child: const Text('Guardar nota')),
          ),
          ...notas.map(
            (n) => Container(
              margin: const EdgeInsets.only(top: 8),
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
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n.contenido,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CronogramaCuotas extends StatelessWidget {
  final List<CronogramaCuotaModel> cronograma;
  final double monto;
  final double cuota;

  const _CronogramaCuotas({
    required this.cronograma,
    required this.monto,
    required this.cuota,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.superficie,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cronograma de cuotas',
            style: TextStyle(
              color: AppTheme.amarillo,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Monto: S/ ${monto.toStringAsFixed(0)} · Cuota: S/ ${cuota.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 32,
              dataRowMinHeight: 28,
              dataRowMaxHeight: 32,
              headingTextStyle: const TextStyle(
                color: AppTheme.amarillo,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              dataTextStyle: const TextStyle(color: Colors.white70, fontSize: 11),
              columns: const [
                DataColumn(label: Text('N°')),
                DataColumn(label: Text('Vencimiento')),
                DataColumn(label: Text('Cuota')),
                DataColumn(label: Text('Capital')),
                DataColumn(label: Text('Interés')),
                DataColumn(label: Text('Saldo')),
              ],
              rows: cronograma
                  .map(
                    (f) => DataRow(
                      cells: [
                        DataCell(Text('${f.numero}')),
                        DataCell(Text(
                          f.fechaVencimiento != null
                              ? FormatoFecha.corta(f.fechaVencimiento)
                              : '—',
                        )),
                        DataCell(Text('S/ ${f.cuota.toStringAsFixed(2)}')),
                        DataCell(Text('S/ ${f.capital.toStringAsFixed(2)}')),
                        DataCell(Text('S/ ${f.interes.toStringAsFixed(2)}')),
                        DataCell(Text('S/ ${f.saldo.toStringAsFixed(2)}')),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Navega a evaluación y refresca listas al volver si hubo cambios.
Future<void> abrirEvaluacionAdmin(
  BuildContext context,
  String solicitudId,
) async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AdminSolicitudEvaluacionScreen(solicitudId: solicitudId),
    ),
  );
  if (!context.mounted) return;
  await Future.wait([
    context.read<AdminSolicitudesTableroViewModel>().refrescar(),
    context.read<AdminRevisionDocumentosViewModel>().cargarLista(),
    context.read<AdminWebInicioViewModel>().cargar(),
  ]);
}
