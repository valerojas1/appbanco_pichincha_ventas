import 'package:flutter/material.dart';

/// Modal bloqueante cuando el cliente está en lista negra.
Future<void> mostrarListaNegraBloqueo(
  BuildContext context, {
  required String documento,
  String? motivo,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: const Color(0xFF3D1515),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        title: const Row(
          children: [
            Icon(Icons.block, color: Colors.redAccent, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Cliente en lista negra',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DNI $documento',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'No es posible continuar con la solicitud de crédito ni operaciones '
              'que requieran consulta de buró favorable.',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
            if (motivo != null && motivo.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Motivo: $motivo',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ENTENDIDO'),
            ),
          ),
        ],
      ),
    ),
  );
}
