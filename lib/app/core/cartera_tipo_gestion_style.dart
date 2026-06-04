import 'package:flutter/material.dart';

class CarteraTipoGestionStyle {
  static Color color(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'RENOVACION':
        return const Color(0xFF1E88E5);
      case 'AMPLIACION':
        return const Color(0xFF43A047);
      case 'NUEVA SOLICITUD':
        return const Color(0xFFFB8C00);
      case 'SEGUIMIENTO':
        return const Color(0xFF9E9E9E);
      case 'RECUPERACION MORA':
        return const Color(0xFFE53935);
      case 'DESERTOR':
        return const Color(0xFF8E24AA);
      default:
        return Colors.grey;
    }
  }

  static String etiquetaCorta(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'RENOVACION':
        return 'RENOVACIÓN';
      case 'AMPLIACION':
        return 'AMPLIACIÓN';
      case 'NUEVA SOLICITUD':
        return 'NUEVA SOL.';
      case 'SEGUIMIENTO':
        return 'SEGUIMIENTO';
      case 'RECUPERACION MORA':
        return 'RECUP. MORA';
      case 'DESERTOR':
        return 'DESERTOR';
      default:
        return tipo;
    }
  }
}
