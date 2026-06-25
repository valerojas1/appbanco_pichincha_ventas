import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Slider de monto con edición manual al tocar el valor mostrado.
class MontoEditableSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final String etiqueta;
  final String? prefijo;

  const MontoEditableSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.etiqueta = 'Monto solicitado',
    this.prefijo = 'S/',
  });

  double _clamp(double v) => v.clamp(min, max);

  /// Ajuste al paso del slider (solo para arrastre, no para entrada manual).
  double _snapSlider(double v) {
    final clamped = _clamp(v);
    if (divisions == null || divisions! <= 0) return clamped;
    final step = (max - min) / divisions!;
    final ticks = ((clamped - min) / step).round();
    return min + step * ticks;
  }

  Future<void> _editarMonto(BuildContext context) async {
    final resultado = await showDialog<double>(
      context: context,
      builder: (ctx) => _DialogoEditarMonto(
        valorInicial: _clamp(value),
        min: min,
        max: max,
        etiqueta: etiqueta,
        prefijo: prefijo,
      ),
    );
    if (resultado == null) return;
    onChanged(_clamp(resultado).roundToDouble());
  }

  @override
  Widget build(BuildContext context) {
    final montoMostrado = _clamp(value).round();
    final posicionSlider = _snapSlider(value);
    final textoMonto = '${prefijo ?? ''} $montoMostrado';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$etiqueta: ',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            GestureDetector(
              onTap: () => _editarMonto(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.amarillo.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppTheme.amarillo.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      textoMonto,
                      style: const TextStyle(
                        color: AppTheme.amarillo,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.edit, size: 14, color: AppTheme.amarillo),
                  ],
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: posicionSlider,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: AppTheme.amarillo,
          label: montoMostrado.toString(),
          onChanged: (v) => onChanged(_snapSlider(v)),
        ),
      ],
    );
  }
}

class _DialogoEditarMonto extends StatefulWidget {
  final double valorInicial;
  final double min;
  final double max;
  final String etiqueta;
  final String? prefijo;

  const _DialogoEditarMonto({
    required this.valorInicial,
    required this.min,
    required this.max,
    required this.etiqueta,
    this.prefijo,
  });

  @override
  State<_DialogoEditarMonto> createState() => _DialogoEditarMontoState();
}

/// Slider de antigüedad (meses) con edición manual al tocar el valor mostrado.
class AntiguedadEditableSlider extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final int? divisions;
  final ValueChanged<int> onChanged;
  final String etiqueta;

  const AntiguedadEditableSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.etiqueta = 'Antigüedad',
  });

  int _clamp(int v) => v.clamp(min, max);

  int _snapSlider(int v) {
    final clamped = _clamp(v);
    if (divisions == null || divisions! <= 0) return clamped;
    final step = (max - min) / divisions!;
    final ticks = ((clamped - min) / step).round();
    return (min + step * ticks).round();
  }

  Future<void> _editarAntiguedad(BuildContext context) async {
    final resultado = await showDialog<int>(
      context: context,
      builder: (ctx) => _DialogoEditarEntero(
        valorInicial: _clamp(value),
        min: min,
        max: max,
        etiqueta: etiqueta,
        sufijo: 'meses',
      ),
    );
    if (resultado == null) return;
    onChanged(_clamp(resultado));
  }

  @override
  Widget build(BuildContext context) {
    final mesesMostrados = _clamp(value);
    final posicionSlider = _snapSlider(value).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$etiqueta: ',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            GestureDetector(
              onTap: () => _editarAntiguedad(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.amarillo.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppTheme.amarillo.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$mesesMostrados meses (mín. $min)',
                      style: const TextStyle(
                        color: AppTheme.amarillo,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.edit, size: 14, color: AppTheme.amarillo),
                  ],
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: posicionSlider,
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: divisions,
          activeColor: AppTheme.amarillo,
          label: '$mesesMostrados meses',
          onChanged: (v) => onChanged(_snapSlider(v.round())),
        ),
      ],
    );
  }
}

class _DialogoEditarEntero extends StatefulWidget {
  final int valorInicial;
  final int min;
  final int max;
  final String etiqueta;
  final String sufijo;

  const _DialogoEditarEntero({
    required this.valorInicial,
    required this.min,
    required this.max,
    required this.etiqueta,
    required this.sufijo,
  });

  @override
  State<_DialogoEditarEntero> createState() => _DialogoEditarEnteroState();
}

class _DialogoEditarEnteroState extends State<_DialogoEditarEntero> {
  late final TextEditingController _ctrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.valorInicial.toString());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _aceptar() {
    final n = int.tryParse(_ctrl.text.trim());
    if (n == null || n <= 0) {
      setState(() => _error = 'Ingrese un valor válido');
      return;
    }
    if (n < widget.min || n > widget.max) {
      setState(
        () => _error =
            'Debe estar entre ${widget.min} y ${widget.max} ${widget.sufijo}',
      );
      return;
    }
    Navigator.pop(context, n);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.superficie,
      title: Text(
        'Editar ${widget.etiqueta}',
        style: const TextStyle(color: AppTheme.amarillo, fontSize: 16),
      ),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(color: Colors.white, fontSize: 18),
        decoration: InputDecoration(
          suffixText: widget.sufijo,
          suffixStyle: const TextStyle(color: AppTheme.amarillo),
          hintText: 'Ingrese los meses',
          hintStyle: const TextStyle(color: Colors.white38),
          helperText: 'Rango: ${widget.min} – ${widget.max} ${widget.sufijo}',
          helperStyle: const TextStyle(color: Colors.white54, fontSize: 11),
          errorText: _error,
        ),
        onSubmitted: (_) => _aceptar(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _aceptar,
          child: const Text('Aceptar'),
        ),
      ],
    );
  }
}

class _DialogoEditarMontoState extends State<_DialogoEditarMonto> {
  late final TextEditingController _ctrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.valorInicial.round().toString(),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _aceptar() {
    final n = double.tryParse(_ctrl.text.trim());
    if (n == null || n <= 0) {
      setState(() => _error = 'Ingrese un monto válido');
      return;
    }
    if (n < widget.min || n > widget.max) {
      setState(
        () => _error =
            'El monto debe estar entre ${widget.min.round()} y ${widget.max.round()}',
      );
      return;
    }
    Navigator.pop(context, n);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.superficie,
      title: Text(
        'Editar ${widget.etiqueta}',
        style: const TextStyle(color: AppTheme.amarillo, fontSize: 16),
      ),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(color: Colors.white, fontSize: 18),
        decoration: InputDecoration(
          prefixText: '${widget.prefijo ?? ''} ',
          prefixStyle: const TextStyle(color: AppTheme.amarillo),
          hintText: 'Ingrese el monto',
          hintStyle: const TextStyle(color: Colors.white38),
          helperText:
              'Rango: ${widget.min.round()} – ${widget.max.round()}',
          helperStyle: const TextStyle(color: Colors.white54, fontSize: 11),
          errorText: _error,
        ),
        onSubmitted: (_) => _aceptar(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _aceptar,
          child: const Text('Aceptar'),
        ),
      ],
    );
  }
}
