import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/oficial_scaffold.dart';
import '../../viewmodel/auth_oficial_viewmodel.dart';
import '../../services/cliente_desertor_service.dart';

class ClienteDesertorScreen extends StatefulWidget {
  final bool embedded;
  final String? nombreInicial;
  final String? documentoInicial;
  final String? clienteid;

  const ClienteDesertorScreen({
    super.key,
    this.embedded = false,
    this.nombreInicial,
    this.documentoInicial,
    this.clienteid,
  });

  @override
  State<ClienteDesertorScreen> createState() => _ClienteDesertorScreenState();
}

class _ClienteDesertorScreenState extends State<ClienteDesertorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = ClienteDesertorService();
  late final TextEditingController _nombreController;
  late final TextEditingController _documentoController;
  late final TextEditingController _motivoController;
  late final TextEditingController _institucionController;
  late final TextEditingController _observacionesController;
  double _probabilidad = 30;
  bool _enviando = false;

  static const _motivos = [
    'Mejor tasa en competencia',
    'Cierre del negocio',
    'Mala experiencia de servicio',
    'Sin necesidad de crédito',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.nombreInicial ?? '');
    _documentoController =
        TextEditingController(text: widget.documentoInicial ?? '');
    _motivoController = TextEditingController();
    _institucionController = TextEditingController();
    _observacionesController = TextEditingController();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _documentoController.dispose();
    _motivoController.dispose();
    _institucionController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final oficial = context.read<AuthOficialViewModel>().oficial;
    if (oficial == null) return;

    setState(() => _enviando = true);
    final ok = await _service.registrar(
      asesorid: oficial.asesorid,
      nombrecliente: _nombreController.text.trim(),
      documento: _documentoController.text.trim().isEmpty
          ? null
          : _documentoController.text.trim(),
      clienteid: widget.clienteid,
      motivo: _motivoController.text.trim(),
      instituciondestino: _institucionController.text.trim(),
      probabilidadretorno: _probabilidad.round(),
      observaciones: _observacionesController.text.trim(),
    );
    setState(() => _enviando = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Registro de desertor guardado' : 'Error al guardar',
        ),
        backgroundColor: ok ? null : Colors.redAccent,
      ),
    );
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return OficialScaffold(
      embedded: widget.embedded,
      title: 'Cliente desertor',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Registro de salida del cliente hacia otra institución',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Nombre del cliente',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _documentoController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Documento (opcional)',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: null,
                dropdownColor: AppTheme.superficie,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Motivo (seleccione o escriba abajo)',
                  prefixIcon: Icon(Icons.help_outline),
                ),
                items: _motivos
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) _motivoController.text = v;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _motivoController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Motivo de salida',
                  prefixIcon: Icon(Icons.exit_to_app),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _institucionController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Institución destino',
                  prefixIcon: Icon(Icons.account_balance),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              Text(
                'Probabilidad de retorno: ${_probabilidad.round()}%',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Slider(
                value: _probabilidad,
                min: 0,
                max: 100,
                divisions: 20,
                activeColor: AppTheme.amarillo,
                label: '${_probabilidad.round()}%',
                onChanged: (v) => setState(() => _probabilidad = v),
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
              ElevatedButton(
                onPressed: _enviando ? null : _guardar,
                child: _enviando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.navy,
                        ),
                      )
                    : const Text('REGISTRAR DESERCIÓN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
