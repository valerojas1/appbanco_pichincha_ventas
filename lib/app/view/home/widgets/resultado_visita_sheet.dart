import 'package:flutter/material.dart';
import '../../../ui/theme/app_theme.dart';

class ResultadoVisitaSheet extends StatefulWidget {
  final String nombreCliente;

  const ResultadoVisitaSheet({super.key, required this.nombreCliente});

  @override
  State<ResultadoVisitaSheet> createState() => _ResultadoVisitaSheetState();
}

class _ResultadoVisitaSheetState extends State<ResultadoVisitaSheet> {
  String? _resultado;
  final _obsController = TextEditingController();

  static const _opciones = [
    ('visitado', 'Visitado', Icons.check_circle, AppTheme.verdePendiente),
    ('no_encontrado', 'No encontrado', Icons.person_off, Colors.orangeAccent),
    ('reagendar', 'Reagendar', Icons.event_repeat, AppTheme.azulVisitado),
    ('negocio_cerrado', 'Negocio cerrado', Icons.store_mall_directory_outlined,
        Colors.redAccent),
  ];

  @override
  void dispose() {
    _obsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Resultado de visita',
            style: TextStyle(
              color: AppTheme.amarillo,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.nombreCliente,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ..._opciones.map((op) {
            final sel = _resultado == op.$1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _resultado = op.$1),
                icon: Icon(op.$3, color: sel ? op.$4 : Colors.white38, size: 20),
                label: Text(
                  op.$2,
                  style: TextStyle(
                    color: sel ? op.$4 : Colors.white70,
                    fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  side: BorderSide(
                    color: sel ? op.$4 : Colors.white24,
                    width: sel ? 2 : 1,
                  ),
                  backgroundColor: sel
                      ? op.$4.withValues(alpha: 0.12)
                      : AppTheme.superficie,
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          TextField(
            controller: _obsController,
            maxLength: 200,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Observación (máx. 200 caracteres)',
              counterStyle: TextStyle(color: Colors.white38),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _resultado == null
                ? null
                : () => Navigator.pop(context, {
                      'resultado': _resultado,
                      'observacion': _obsController.text.trim(),
                    }),
            child: const Text('REGISTRAR Y SALIR'),
          ),
        ],
      ),
    );
  }
}
