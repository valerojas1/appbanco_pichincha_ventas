import 'package:flutter/material.dart';
import '../ui/theme/app_theme.dart';

/// Estados del ciclo de vida de una solicitud (Bloque 8).
enum EstadoSolicitud {
  documentosPendientes('documentos_pendientes', 'Documentos pendientes'),
  completa('completa', 'Lista para transmitir'),
  enviada('enviada', 'Enviada'),
  enComite('en_comite', 'En comité'),
  aprobada('aprobada', 'Aprobada'),
  desembolsada('desembolsada', 'Desembolsada'),
  rechazada('rechazada', 'Rechazada');

  final String dbValue;
  final String etiqueta;

  const EstadoSolicitud(this.dbValue, this.etiqueta);

  static EstadoSolicitud? fromDb(String? v) {
    if (v == null) return null;
    for (final e in EstadoSolicitud.values) {
      if (e.dbValue == v) return e;
    }
    return null;
  }

  Color get color {
    switch (this) {
      case EstadoSolicitud.documentosPendientes:
        return Colors.orangeAccent;
      case EstadoSolicitud.completa:
        return AppTheme.azulVisitado;
      case EstadoSolicitud.enviada:
        return AppTheme.amarillo;
      case EstadoSolicitud.enComite:
        return Colors.deepPurpleAccent;
      case EstadoSolicitud.aprobada:
        return AppTheme.verdePendiente;
      case EstadoSolicitud.desembolsada:
        return Colors.lightGreenAccent;
      case EstadoSolicitud.rechazada:
        return Colors.redAccent;
    }
  }

  /// Pestaña del tablero (null = no aparece en tablero principal).
  TabSolicitud? get tab {
    switch (this) {
      case EstadoSolicitud.enviada:
        return TabSolicitud.enviadas;
      case EstadoSolicitud.enComite:
        return TabSolicitud.enComite;
      case EstadoSolicitud.aprobada:
        return TabSolicitud.aprobadas;
      case EstadoSolicitud.desembolsada:
        return TabSolicitud.desembolsadas;
      case EstadoSolicitud.rechazada:
        return TabSolicitud.rechazadas;
      default:
        return null;
    }
  }
}

enum TabSolicitud {
  enviadas,
  enComite,
  aprobadas,
  desembolsadas,
  rechazadas,
}

extension TabSolicitudExt on TabSolicitud {
  String get titulo {
    switch (this) {
      case TabSolicitud.enviadas:
        return 'Enviadas';
      case TabSolicitud.enComite:
        return 'En comité';
      case TabSolicitud.aprobadas:
        return 'Aprobadas';
      case TabSolicitud.desembolsadas:
        return 'Desembolsadas';
      case TabSolicitud.rechazadas:
        return 'Rechazadas';
    }
  }

  List<String> get estadosDb {
    switch (this) {
      case TabSolicitud.enviadas:
        return ['enviada'];
      case TabSolicitud.enComite:
        return ['en_comite'];
      case TabSolicitud.aprobadas:
        return ['aprobada'];
      case TabSolicitud.desembolsadas:
        return ['desembolsada'];
      case TabSolicitud.rechazadas:
        return ['rechazada'];
    }
  }
}
