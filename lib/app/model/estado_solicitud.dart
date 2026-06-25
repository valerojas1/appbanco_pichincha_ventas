import 'package:flutter/material.dart';

import '../ui/theme/app_theme.dart';



/// Estados del ciclo de vida de una solicitud.

enum EstadoSolicitud {

  pendienteOperador('pendiente_operador', 'Pendiente de operador'),

  enAtencion('en_atencion', 'En atención (operador)'),

  documentosPendientes('documentos_pendientes', 'Documentos pendientes'),

  completa('completa', 'Lista para transmitir'),

  enviada('enviada', 'Enviada'),

  recibidoComite('recibido_comite', 'Recibido en comité'),

  enEvaluacion('en_evaluacion', 'En evaluación'),

  enComite('en_comite', 'En comité'),

  aprobada('aprobada', 'Aprobada'),

  condicionada('condicionada', 'Condicionada'),

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

      case EstadoSolicitud.pendienteOperador:

        return AppTheme.naranjaNuevo;

      case EstadoSolicitud.enAtencion:

        return AppTheme.azulVisitado;

      case EstadoSolicitud.documentosPendientes:

        return Colors.orangeAccent;

      case EstadoSolicitud.completa:

        return AppTheme.azulVisitado;

      case EstadoSolicitud.enviada:

        return AppTheme.amarillo;

      case EstadoSolicitud.recibidoComite:

        return Colors.tealAccent;

      case EstadoSolicitud.enEvaluacion:

        return Colors.deepPurpleAccent;

      case EstadoSolicitud.enComite:

        return Colors.deepPurpleAccent;

      case EstadoSolicitud.aprobada:

        return AppTheme.verdePendiente;

      case EstadoSolicitud.condicionada:

        return Colors.amberAccent;

      case EstadoSolicitud.desembolsada:

        return Colors.lightGreenAccent;

      case EstadoSolicitud.rechazada:

        return Colors.redAccent;

    }

  }



  TabSolicitud? get tab {

    switch (this) {

      case EstadoSolicitud.recibidoComite:

        return TabSolicitud.recibidas;

      case EstadoSolicitud.enEvaluacion:

        return TabSolicitud.enEvaluacion;

      case EstadoSolicitud.enviada:

        return TabSolicitud.enviadas;

      case EstadoSolicitud.enComite:

        return TabSolicitud.enComite;

      case EstadoSolicitud.aprobada:

        return TabSolicitud.aprobadas;

      case EstadoSolicitud.condicionada:

        return TabSolicitud.condicionadas;

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

  recibidas,

  enEvaluacion,

  enviadas,

  enComite,

  aprobadas,

  condicionadas,

  desembolsadas,

  rechazadas,

}



extension TabSolicitudExt on TabSolicitud {

  String get titulo {

    switch (this) {

      case TabSolicitud.recibidas:

        return 'Recibidas';

      case TabSolicitud.enEvaluacion:

        return 'En evaluación';

      case TabSolicitud.enviadas:

        return 'Enviadas';

      case TabSolicitud.enComite:

        return 'En comité';

      case TabSolicitud.aprobadas:

        return 'Aprobadas';

      case TabSolicitud.condicionadas:

        return 'Condicionadas';

      case TabSolicitud.desembolsadas:

        return 'Desembolsadas';

      case TabSolicitud.rechazadas:

        return 'Rechazadas';

    }

  }



  List<String> get estadosDb {

    switch (this) {

      case TabSolicitud.recibidas:

        return ['recibido_comite'];

      case TabSolicitud.enEvaluacion:

        return ['en_evaluacion'];

      case TabSolicitud.enviadas:

        return ['enviada'];

      case TabSolicitud.enComite:

        return ['en_comite'];

      case TabSolicitud.aprobadas:

        return ['aprobada'];

      case TabSolicitud.condicionadas:

        return ['condicionada'];

      case TabSolicitud.desembolsadas:

        return ['desembolsada'];

      case TabSolicitud.rechazadas:

        return ['rechazada'];

    }

  }

}

