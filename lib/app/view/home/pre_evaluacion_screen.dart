import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/campana_activa_model.dart';
import '../../model/preevaluacion_resultado_model.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/oficial_scaffold.dart';
import '../../viewmodel/auth_oficial_viewmodel.dart';
import '../../viewmodel/prospeccion_viewmodel.dart';
import 'ficha_cliente_screen.dart';
import 'solicitud_credito_wizard_screen.dart';
import '../../core/buro_solicitud_gate.dart';
import 'widgets/campanas_activas_section.dart';

class PreEvaluacionScreen extends StatefulWidget {
  final bool embedded;
  final ProspectoSolicitudPrefill? prefill;

  const PreEvaluacionScreen({super.key, this.embedded = false, this.prefill});

  @override
  State<PreEvaluacionScreen> createState() => _PreEvaluacionScreenState();
}

class _PreEvaluacionScreenState extends State<PreEvaluacionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _dniController;
  late final TextEditingController _nombresController;
  late final TextEditingController _tipoNegocioController;
  late final TextEditingController _ingresosController;
  String _destino = 'capital_trabajo';
  double _monto = 5000;

  static const _destinos = [
    ('capital_trabajo', 'Capital de trabajo'),
    ('compra_inventario', 'Compra de inventario'),
    ('ampliacion_local', 'Ampliación de local'),
    ('equipamiento', 'Equipamiento'),
    ('inversion', 'Inversión en negocio'),
    ('otro', 'Otro'),
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.prefill;
    _dniController = TextEditingController(text: p?.dni ?? '');
    _nombresController = TextEditingController(text: p?.nombres ?? '');
    _tipoNegocioController = TextEditingController(text: p?.tiponegocio ?? '');
    _ingresosController = TextEditingController(
      text: p != null ? p.ingresos.toStringAsFixed(0) : '',
    );
    if (p != null) {
      _monto = p.monto.clamp(500, 50000);
      _destino = p.destino;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _iniciar());
  }

  void _iniciar() {
    final auth = context.read<AuthOficialViewModel>().oficial;
    if (auth == null) return;
    final vm = context.read<ProspeccionViewModel>();
    vm.cargarCampanas(auth.asesorid);
    vm.actualizarCola();
    vm.sincronizarCola();
  }

  @override
  void dispose() {
    _dniController.dispose();
    _nombresController.dispose();
    _tipoNegocioController.dispose();
    _ingresosController.dispose();
    super.dispose();
  }

  Color _colorResultado(PreEvaluacionResultadoModel? r) {
    if (r == null) return Colors.white54;
    if (r.esApto) return AppTheme.verdePendiente;
    if (r.esRevisar) return AppTheme.amarillo;
    return Colors.redAccent;
  }

  Future<void> _preEvaluar() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthOficialViewModel>().oficial;
    if (auth == null) return;

    await context.read<ProspeccionViewModel>().preEvaluar(
          asesorid: auth.asesorid,
          dni: _dniController.text.trim(),
          nombres: _nombresController.text.trim(),
          tiponegocio: _tipoNegocioController.text.trim(),
          ingresos: double.parse(_ingresosController.text.trim()),
          destino: _destino,
          monto: _monto,
        );
  }

  void _gestionarCampana(CampanaActivaModel c) {
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
      return;
    }
    _nombresController.text = c.nombrecliente;
    setState(() => _monto = c.montooferta.clamp(500, 50000));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProspeccionViewModel>();
    final resultado = vm.resultado;

    return OficialScaffold(
      embedded: widget.embedded,
      title: 'Pre-evaluación',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (vm.colaPendiente > 0)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '${vm.colaPendiente} pre-evaluación(es) en cola. Se procesarán al reconectar.',
                    style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
                  ),
                ),
              CampanasActivasSection(
                campanas: vm.campanas,
                onGestionar: _gestionarCampana,
              ),
              const SizedBox(height: 24),
              const Text(
                'Nuevo prospecto',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dniController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'DNI',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().length < 8) ? 'DNI inválido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nombresController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Nombres y apellidos',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tipoNegocioController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Tipo de negocio',
                  prefixIcon: Icon(Icons.store_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ingresosController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Ingresos estimados (S/)',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                validator: (v) {
                  final n = double.tryParse(v?.trim() ?? '');
                  if (n == null || n <= 0) return 'Ingrese un monto válido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _destino,
                dropdownColor: AppTheme.superficie,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Destino del crédito',
                  prefixIcon: Icon(Icons.track_changes),
                ),
                items: _destinos
                    .map(
                      (d) => DropdownMenuItem(
                        value: d.$1,
                        child: Text(d.$2),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _destino = v);
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Monto solicitado: S/ ${_monto.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Slider(
                value: _monto,
                min: 500,
                max: 50000,
                divisions: 99,
                activeColor: AppTheme.amarillo,
                label: 'S/ ${_monto.toStringAsFixed(0)}',
                onChanged: (v) => setState(() => _monto = v),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: vm.evaluando ? null : _preEvaluar,
                  child: vm.evaluando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.navy,
                          ),
                        )
                      : const Text('PRE-EVALUAR'),
                ),
              ),
              if (resultado != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _colorResultado(resultado).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _colorResultado(resultado).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resultado.resultado,
                        style: TextStyle(
                          color: _colorResultado(resultado),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      if (vm.enCola)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'En cola — se confirmará al reconectar',
                            style: TextStyle(color: Colors.orangeAccent, fontSize: 11),
                          ),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        resultado.mensaje,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      if (resultado.ratioDeudaIngreso != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Ratio monto/ingreso: ${resultado.ratioDeudaIngreso!.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ),
                if (resultado.esApto && vm.ultimoProspecto != null) ...[
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final p = vm.ultimoProspecto!;
                      final ok = await BuroSolicitudGate.validarAntesDeSolicitud(
                        context,
                        dni: p.dni,
                        nombres: p.nombres,
                      );
                      if (!context.mounted || !ok) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SolicitudCreditoWizardScreen(
                            prefill: p,
                          ),
                        ),
                      );
                    },
                    child: const Text('INICIAR SOLICITUD DE CRÉDITO'),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
