import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/preevaluacion_resultado_model.dart';
import '../../ui/theme/app_theme.dart';
import '../../viewmodel/auth_oficial_viewmodel.dart';
import '../../viewmodel/ficha_viewmodel.dart';

class SolicitudFormalScreen extends StatefulWidget {
  final ProspectoSolicitudPrefill prefill;

  const SolicitudFormalScreen({super.key, required this.prefill});

  @override
  State<SolicitudFormalScreen> createState() => _SolicitudFormalScreenState();
}

class _SolicitudFormalScreenState extends State<SolicitudFormalScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _dniController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _rubroController;
  late final TextEditingController _ingresoController;
  late final TextEditingController _montoController;
  late final TextEditingController _observacionesController;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    final p = widget.prefill;
    _nombreController = TextEditingController(text: p.nombres);
    _dniController = TextEditingController(text: p.dni);
    _telefonoController = TextEditingController();
    _rubroController = TextEditingController(text: p.tiponegocio);
    _ingresoController = TextEditingController(text: p.ingresos.toStringAsFixed(0));
    _montoController = TextEditingController(text: p.monto.toStringAsFixed(0));
    _observacionesController = TextEditingController(
      text: 'Destino: ${p.destino}. Pre-evaluación APTO.',
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _dniController.dispose();
    _telefonoController.dispose();
    _rubroController.dispose();
    _ingresoController.dispose();
    _montoController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);

    final oficial = context.read<AuthOficialViewModel>().oficial;
    final data = {
      'asesorid': oficial?.userid ?? oficial?.asesorid ?? '',
      'prospectonombre': _nombreController.text.trim(),
      'prospectodni': _dniController.text.trim(),
      'prospectotelefono': _telefonoController.text.trim(),
      'negociorubro': _rubroController.text.trim(),
      'ingresodeclarado': double.tryParse(_ingresoController.text.trim()) ?? 0,
      'montosolicitado': double.tryParse(_montoController.text.trim()) ?? 0,
      'observaciones': _observacionesController.text.trim(),
      'estadoficha': 'solicitud_formal',
      'tipovisita': 'prospeccion',
    };

    final ok = await context.read<FichaViewModel>().guardarFicha(data);
    setState(() => _enviando = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Solicitud formal registrada'
              : 'Error al registrar solicitud',
        ),
        backgroundColor: ok ? null : Colors.redAccent,
      ),
    );
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondoOscuro,
      appBar: AppBar(
        title: const Text(
          'Solicitud formal',
          style: TextStyle(
            color: AppTheme.amarillo,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                'Datos prellenados desde la pre-evaluación APTO',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Nombre del prospecto',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dniController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'DNI',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telefonoController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Teléfono contacto',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _rubroController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Rubro / tipo negocio',
                  prefixIcon: Icon(Icons.store),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ingresoController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Ingreso declarado (S/)',
                  prefixIcon: Icon(Icons.payments),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _montoController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Monto solicitado (S/)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _observacionesController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Observaciones',
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _enviando ? null : _enviar,
                  child: _enviando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.navy,
                          ),
                        )
                      : const Text('ENVIAR SOLICITUD'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
