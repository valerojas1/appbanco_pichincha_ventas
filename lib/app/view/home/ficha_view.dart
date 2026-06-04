import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/ficha_viewmodel.dart';
import '../../viewmodel/auth_oficial_viewmodel.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/oficial_scaffold.dart';

class FichaView extends StatefulWidget {
  final bool embedded;

  const FichaView({super.key, this.embedded = false});

  @override
  State<FichaView> createState() => _FichaViewState();
}

class _FichaViewState extends State<FichaView> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _dniController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _tipoNegocioController = TextEditingController();
  final _ingresoController = TextEditingController();
  final _gastoController = TextEditingController();
  final _referenciasController = TextEditingController();
  final _observacionesController = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _dniController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _tipoNegocioController.dispose();
    _ingresoController.dispose();
    _gastoController.dispose();
    _referenciasController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _enviando = true);

    final oficial = context.read<AuthOficialViewModel>().oficial;
    final data = {
      'asesorid': oficial?.userid ?? '',
      'nombrecliente': _nombreController.text.trim(),
      'apellidocliente': _apellidoController.text.trim(),
      'dnifliente': _dniController.text.trim(),
      'direccion': _direccionController.text.trim(),
      'telefonocontacto': _telefonoController.text.trim(),
      'tiponegocio': _tipoNegocioController.text.trim(),
      'ingresomensual': double.tryParse(_ingresoController.text.trim()) ?? 0,
      'gastosmensuales': double.tryParse(_gastoController.text.trim()) ?? 0,
      'referencias': _referenciasController.text.trim(),
      'observaciones': _observacionesController.text.trim(),
      'estadoficha': 'completada',
    };

    final vm = context.read<FichaViewModel>();
    final success = await vm.guardarFicha(data);

    setState(() => _enviando = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ficha guardada correctamente')),
        );
        _limpiarFormulario();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error al guardar la ficha'),
              backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _limpiarFormulario() {
    _nombreController.clear();
    _apellidoController.clear();
    _dniController.clear();
    _direccionController.clear();
    _telefonoController.clear();
    _tipoNegocioController.clear();
    _ingresoController.clear();
    _gastoController.clear();
    _referenciasController.clear();
    _observacionesController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FichaViewModel>();

    return OficialScaffold(
      embedded: widget.embedded,
      title: 'Ficha de Campo',
      actions: [
        if (vm.offlineCount > 0)
          TextButton.icon(
            onPressed: () => vm.sincronizar(),
            icon: const Icon(Icons.sync, color: AppTheme.amarillo, size: 18),
            label: Text(
              '${vm.offlineCount}',
              style: const TextStyle(color: AppTheme.amarillo, fontSize: 13),
            ),
          ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!vm.online)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orangeAccent.withOpacity(0.5)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.wifi_off, color: Colors.orangeAccent, size: 18),
                      SizedBox(width: 8),
                      Text('Modo offline — los datos se guardarán localmente',
                          style: TextStyle(color: Colors.orangeAccent, fontSize: 13)),
                    ],
                  ),
                ),
              TextFormField(
                controller: _nombreController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: 'Nombre del Cliente *',
                    prefixIcon: Icon(Icons.person)),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Campo obligatorio'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _apellidoController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: 'Apellido del Cliente *',
                    prefixIcon: Icon(Icons.person_outline)),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Campo obligatorio'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _dniController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: 'DNI *',
                    prefixIcon: Icon(Icons.badge_outlined)),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Campo obligatorio'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _direccionController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: 'Dirección *',
                    prefixIcon: Icon(Icons.location_on_outlined)),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Campo obligatorio'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _telefonoController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: 'Teléfono de Contacto',
                    prefixIcon: Icon(Icons.phone_outlined)),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _tipoNegocioController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: 'Tipo de Negocio *',
                    prefixIcon: Icon(Icons.store_outlined)),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Campo obligatorio'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _ingresoController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Ingreso Mensual (S/) *',
                    prefixIcon: Icon(Icons.trending_up)),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Campo obligatorio';
                  if (double.tryParse(v.trim()) == null) return 'Ingrese un número válido';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _gastoController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Gastos Mensuales (S/) *',
                    prefixIcon: Icon(Icons.trending_down)),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Campo obligatorio';
                  if (double.tryParse(v.trim()) == null) return 'Ingrese un número válido';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _referenciasController,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Referencias',
                    prefixIcon: Icon(Icons.notes)),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _observacionesController,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Observaciones',
                    prefixIcon: Icon(Icons.comment_outlined)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _enviando || vm.loading ? null : _guardar,
                  child: _enviando || vm.loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppTheme.navy))
                      : const Text('GUARDAR FICHA'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
