import 'package:flutter/material.dart';
import '../ui/theme/app_theme.dart';

class CampanaTipoStyle {
  static Color color(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'preaprobado':
        return AppTheme.verdePendiente;
      case 'mora':
        return Colors.redAccent;
      case 'renovacion':
        return AppTheme.azulVisitado;
      case 'retencion':
        return AppTheme.amarillo;
      case 'reactivacion':
        return AppTheme.naranjaNuevo;
      default:
        return Colors.white54;
    }
  }

  static String etiqueta(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'preaprobado':
        return 'Preaprobado';
      case 'mora':
        return 'Recuperación mora';
      case 'renovacion':
        return 'Renovación';
      case 'retencion':
        return 'Retención';
      case 'reactivacion':
        return 'Reactivación';
      default:
        return tipo;
    }
  }
}
