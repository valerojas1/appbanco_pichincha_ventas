import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';
import '../../core/buro_texto_legal.dart';
import '../../core/buro_solicitud_gate.dart';
import '../../model/consulta_buro_resultado_model.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/oficial_scaffold.dart';
import '../../viewmodel/auth_oficial_viewmodel.dart';
import '../../viewmodel/consulta_buro_viewmodel.dart';

class ConsultaBuroArgs {
  final String documento;
  final String? nombres;

  const ConsultaBuroArgs({required this.documento, this.nombres});
}

class ConsultaBuroScreen extends StatefulWidget {
  final bool embedded;
  final ConsultaBuroArgs? args;

  const ConsultaBuroScreen({super.key, this.embedded = false, this.args});

  @override
  State<ConsultaBuroScreen> createState() => _ConsultaBuroScreenState();
}

class _ConsultaBuroScreenState extends State<ConsultaBuroScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _dniController;
  late final TextEditingController _nombresController;
  final _sigController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.white,
    exportBackgroundColor: AppTheme.navyOscuro,
  );

  bool _mostrandoConsentimiento = false;
  bool _reutilizarConsulta = false;

  @override
  void initState() {
    super.initState();
    final args = widget.args;
    _dniController = TextEditingController(text: args?.documento ?? '');
    _nombresController = TextEditingController(text: args?.nombres ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConsultaBuroViewModel>().reiniciar();
      if (args != null) {
        final vm = context.read<ConsultaBuroViewModel>();
        vm.setDocumento(args.documento);
        if (args.nombres != null) vm.setNombres(args.nombres!);
      }
    });
  }

  @override
  void dispose() {
    _dniController.dispose();
    _nombresController.dispose();
    _sigController.dispose();
    super.dispose();
  }

  Future<void> _iniciarFlujo() async {
    if (!_formKey.currentState!.validate()) return;

    final vm = context.read<ConsultaBuroViewModel>();
    vm.setDocumento(_dniController.text.trim());
    vm.setNombres(_nombresController.text.trim());
    vm.reiniciar();
    vm.setDocumento(_dniController.text.trim());
    vm.setNombres(_nombresController.text.trim());

    await vm.verificarConsultaReciente();
    if (!mounted) return;

    var reutilizar = false;
    final reciente = vm.consultaReciente;
    if (reciente != null) {
      final decision = await _dialogoReutilizar(reciente);
      if (!mounted) return;
      if (decision == null) return;
      reutilizar = decision == _DecisionReutilizar.reutilizar;
    }
    setState(() {
      _reutilizarConsulta = reutilizar;
      _mostrandoConsentimiento = true;
    });
  }

  Future<_DecisionReutilizar?> _dialogoReutilizar(
    ConsultaBuroRecienteModel rec,
  ) async {
    return showDialog<_DecisionReutilizar>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.superficie,
        title: const Text(
          'Consulta reciente',
          style: TextStyle(color: AppTheme.amarillo),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Existe una consulta de los últimos 30 días. Puede reutilizarla '
              '(no genera nueva consulta externa ni nuevo registro de historial).',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Text(
              'SBS: ${rec.clasificacionSbs}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            Text(
              'Deuda total: S/ ${rec.deudaTotal.toStringAsFixed(0)}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            if (rec.enListaNegra)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  '⚠ Esta consulta indica lista negra',
                  style: TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, _DecisionReutilizar.nueva),
            child: const Text('Nueva consulta'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, _DecisionReutilizar.reutilizar),
            child: const Text('REUTILIZAR'),
          ),
        ],
      ),
    );
  }

  Future<void> _ejecutarConsulta({required bool reutilizar}) async {
    final vm = context.read<ConsultaBuroViewModel>();
    if (!vm.consentimientoAceptado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe marcar el consentimiento informado'),
        ),
      );
      return;
    }
    if (_sigController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La firma del cliente es obligatoria')),
      );
      return;
    }
    final bytes = await _sigController.toPngBytes();
    if (bytes == null || bytes.isEmpty) return;
    vm.setFirmaBase64(base64Encode(bytes));

    final auth = context.read<AuthOficialViewModel>().oficial;
    if (auth == null) return;

    final ok = await vm.ejecutarConsulta(
      asesorid: auth.asesorid,
      reutilizar: _reutilizarConsulta,
    );
    if (!mounted) return;

    if (!ok) {
      if (vm.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(vm.error!)),
        );
      }
      return;
    }

    final r = vm.resultado!;
    await BuroSolicitudGate.manejarResultadoConsulta(context, r);
    if (!mounted) return;
    setState(() => _mostrandoConsentimiento = false);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ConsultaBuroViewModel>();

    return OficialScaffold(
      embedded: widget.embedded,
      title: 'Consulta de buró',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: vm.resultado != null && !_mostrandoConsentimiento
            ? _ResultadoBuro(
                resultado: vm.resultado!,
                textoInterpretativo: vm.textoInterpretativo,
                onNuevaConsulta: () {
                  vm.reiniciar();
                  setState(() {
                    _mostrandoConsentimiento = false;
                    _sigController.clear();
                  });
                },
              )
            : _mostrandoConsentimiento
                ? _PasoConsentimiento(
                    sigController: _sigController,
                    vm: vm,
                    onCancelar: () => setState(() => _mostrandoConsentimiento = false),
                    onConfirmar: () => _ejecutarConsulta(
                      reutilizar: vm.consultaReciente != null,
                    ),
                  )
                : Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.amarillo.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.amarillo.withValues(alpha: 0.35),
                            ),
                          ),
                          child: const Text(
                            'Ley N° 29733: consentimiento y firma del cliente son '
                            'obligatorios antes de consultar buró y listas restrictivas.',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _dniController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'DNI del cliente',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          validator: (v) {
                            final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
                            return d.length != 8 ? 'DNI de 8 dígitos' : null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _nombresController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Nombres (opcional)',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        if (vm.cargando) ...[
                          const SizedBox(height: 24),
                          const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.amarillo,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: vm.cargando ? null : _iniciarFlujo,
                          child: const Text('CONTINUAR'),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

enum _DecisionReutilizar { reutilizar, nueva }

class _PasoConsentimiento extends StatelessWidget {
  final SignatureController sigController;
  final ConsultaBuroViewModel vm;
  final VoidCallback onCancelar;
  final VoidCallback onConfirmar;

  const _PasoConsentimiento({
    required this.sigController,
    required this.vm,
    required this.onCancelar,
    required this.onConfirmar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          BuroTextoLegal.titulo,
          style: const TextStyle(
            color: AppTheme.amarillo,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
          child: Text(
            BuroTextoLegal.cuerpo,
            style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
          ),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          value: vm.consentimientoAceptado,
          onChanged: (v) => vm.setConsentimientoAceptado(v == true),
          title: const Text(
            'El cliente acepta el consentimiento informado',
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
          activeColor: AppTheme.amarillo,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 8),
        const Text(
          'Firma del cliente',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: AppTheme.navyOscuro,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Signature(
              controller: sigController,
              backgroundColor: AppTheme.navyOscuro,
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => sigController.clear(),
            child: const Text('Limpiar firma'),
          ),
        ),
        if (vm.cargando)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: CircularProgressIndicator(color: AppTheme.amarillo),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: vm.cargando ? null : onCancelar,
                child: const Text('Volver'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: vm.cargando ? null : onConfirmar,
                child: const Text('CONSULTAR'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ResultadoBuro extends StatelessWidget {
  final ConsultaBuroResultadoModel resultado;
  final String? textoInterpretativo;
  final VoidCallback onNuevaConsulta;

  const _ResultadoBuro({
    required this.resultado,
    required this.textoInterpretativo,
    required this.onNuevaConsulta,
  });

  Color _colorSbs(String sbs) {
    switch (sbs.toUpperCase()) {
      case 'NORMAL':
        return AppTheme.verdePendiente;
      case 'CPP':
        return AppTheme.amarillo;
      default:
        return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sbsColor = _colorSbs(resultado.clasificacionSbs);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (resultado.reutilizada)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.4)),
            ),
            child: Text(
              resultado.mensajeReutilizacion ??
                  'Resultado reutilizado de consulta previa (30 días).',
              style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 12),
            ),
          ),
        if (resultado.enListaNegra)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF3D1515),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.redAccent, width: 2),
            ),
            child: const Row(
              children: [
                Icon(Icons.block, color: Colors.redAccent),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Cliente en lista negra — solicitud de crédito bloqueada',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: sbsColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sbsColor.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calificación SBS: ${resultado.clasificacionSbs}',
                style: TextStyle(
                  color: sbsColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'DNI ${resultado.documento}'
                '${resultado.nombres != null ? ' — ${resultado.nombres}' : ''}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),
              _Metrica(
                label: 'Deuda total',
                valor: 'S/ ${resultado.deudaTotal.toStringAsFixed(0)}',
              ),
              _Metrica(
                label: 'Mayor deuda',
                valor: 'S/ ${resultado.mayorDeuda.toStringAsFixed(0)}',
              ),
              _Metrica(
                label: 'Días mora histórica',
                valor: '${resultado.diasMoraHistorica}',
              ),
            ],
          ),
        ),
        if (resultado.entidadesConDeuda.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Entidades con deuda',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ...resultado.entidadesConDeuda.map(
            (e) => ListTile(
              dense: true,
              tileColor: Colors.white.withValues(alpha: 0.04),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              title: Text(
                e.entidad,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              trailing: Text(
                'S/ ${e.deuda.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: AppTheme.amarillo,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
        if (textoInterpretativo != null) ...[
          const SizedBox(height: 16),
          const Text(
            'Interpretación',
            style: TextStyle(
              color: AppTheme.amarillo,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              textoInterpretativo!,
              style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.45),
            ),
          ),
        ],
        if (resultado.consultaId != null) ...[
          const SizedBox(height: 10),
          Text(
            'Registro auditoría: ${resultado.consultaId}',
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: onNuevaConsulta,
          child: const Text('Nueva consulta'),
        ),
      ],
    );
  }
}

class _Metrica extends StatelessWidget {
  final String label;
  final String valor;

  const _Metrica({required this.label, required this.valor});

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
