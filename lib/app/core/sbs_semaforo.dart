import 'package:flutter/material.dart';

/// Colores del semáforo SBS para la ficha del cliente.
class SbsSemaforo {
  static Color color(String? clasificacion) {
    final c = (clasificacion ?? '').trim().toLowerCase();
    switch (c) {
      case 'normal':
        return const Color(0xFF43A047);
      case 'cpp':
        return const Color(0xFFFFD100);
      case 'deficiente':
        return const Color(0xFFFB8C00);
      case 'dudoso':
        return const Color(0xFFE53935);
      case 'pérdida':
      case 'perdida':
        return const Color(0xFF424242);
      default:
        return Colors.grey;
    }
  }

  static String etiqueta(String? clasificacion) {
    final c = (clasificacion ?? '').trim();
    if (c.isEmpty) return 'Sin clasificar';
    return c.toUpperCase();
  }
}
